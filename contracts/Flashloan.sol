pragma solidity ^0.6.0;

import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";
import "./curveFi/ICurveFi.sol";
import "./uniswap/IUniswapV2Router02.sol";

/*
 Steps to arbitrage and make some profit: 
 * 1. Borrow TokenA from Aave
 * 2. Exchange the TokenA with TokenB on Uniswap
 * 3. Exchange the TokenB with the TokenA on Curve Finance
 * 4. Repay the TokenA to Aave
 * 5. Make some profit
 */
contract FlashLoan is FlashLoanReceiverBase {
    ILendingPool public lendingPool;
    IUniswapV2Router02 public uniswapV2Router02;
    ICurveFi public curveFi;

    address[] public path;

    address constant curveFi_curve_cDai_cUsdc = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;

    constructor(address _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {
        address lendingPoolAddress = addressesProvider.getLendingPool();
        //Instantiate Aave Lending Pool
        lendingPool = ILendingPool(lendingPoolAddress);

        //Instantiate Uniswap V2 router 02
        uniswapV2Router02 = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        //Instantiate curveFi
        curveFi = ICurveFi(curveFi_curve_cDai_cUsdc);
    }

    function flashLoan(
        address tokenA,
        uint256 amount,
        address tokenB
    ) public onlyOwner {
        ERC20 TokenA = ERC20(tokenA);
        bytes memory params = abi.encode(tokenB);

        //  * 1. Borrow TokenA from Aave
        // flashLoan calls the executeOperation
        lendingPool.flashLoan(address(this), tokenA, amount, params);

        //  * 5. Make some profit
        // Any left amount of the TokenA is profit
        uint256 profit = TokenA.balanceOf(address(this));
        // Sending back the profit 💰
        require(
            TokenA.transfer(msg.sender, profit),
            "Could not transfer back the profit"
        );
    }

    /**
        This function is called after your contract has received the flash loaned amount
        https://github.com/aave/aave-protocol/blob/f7ef52000af2964046857da7e5fe01894a51f2ab/contracts/lendingpool/LendingPool.sol#L881
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance, was the flashLoan successful?"
        );

        address _tokenB = abi.decode(_params, (address));

        //  * 2. Exchange TokenA with TokenB on Uniswap
        uint256 deadline = getDeadline();
        ERC20 TokenA = ERC20(_reserve);

        require(
            TokenA.approve(address(uniswapV2Router02), _amount),
            "Could not approve TokenA sell"
        );

        path.push(_reserve);
        path.push(_tokenB);

        uint256[] memory tokenBPurchased = uniswapV2Router02
            .swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            deadline
        );

        //  * 3. Exchange TokenB with TokenA on Curve Finance

        ERC20 TokenB = ERC20(_tokenB);

        require(
            TokenB.approve(address(curveFi), tokenBPurchased[0]),
            "Could not approve TokenB sell"
        );

        curveFi.exchange_underlying(
            int128(_reserve),
            int128(_tokenB),
            tokenBPurchased[0],
            0
        );

        //  * 4. Repay TokenA to Aave
        uint256 totalDebt = _amount.add(_fee);
        require(
            totalDebt <= getBalanceInternal(address(this), _reserve),
            "FlashLoan Fee amount not met."
        );
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function getDeadline() internal view returns (uint256) {
        return block.timestamp + 3000;
    }
}
