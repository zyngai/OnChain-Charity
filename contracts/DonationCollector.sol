// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import openzeppelin library to access the ERC20 interface
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import IERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import the uniswap router
// import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// OCC smart contract
contract DonationsCollector {
    address public owner;
    uint256 public balance;

    event TransferReceived(address _from, uint256 _amount);
    event TransferSent(address _from, address _destAddr, uint256 _amount);

    constructor() {
        owner = msg.sender;
    }

    // receive transactions/donations
    receive() external payable {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    // function that swap tokens from our smart contract

    // address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //address of WETH token
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // swap function that trade one one token to another
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external {
        // transfer token in tokens from msg.sender to this contract
        require(
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn),
            "transaferFrom failed"
        );
        // allow the uniswapv2 router to spend the token we just sent to this contract calling IERC20 approve
        require(
            IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn),
            "approve failed."
        );

        address[] memory path;
        // 2 possible cases in swapping tokens:
        // 1. TokenA -> TokenB
        // 2. TokenA -> WETH (intermediary token) -> TokenB (In most cases, this will get you better price)
        // We consider the second case
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    // CHAINLINK KEEPERS
    // integrate chainlink keepers to automatically swap tokens when we receive it
    // set the time between receiving and swapping token in keepers? Link -> stablecoins
    // functions to send tokens (donations) to designated charities

    // function that transfer/donate tokens to charity
    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);
    }
}

// Useful Info:
// kovan testnet:
// ETH token address:
// Link token address: 0xa36085F69e2889c224210F603D836748e7dC0088
// USDT token address: 0x28e9E3D4d8d17e11EA302913B02c3f26827E5Ab9
// DAI token address: 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
// contract tested:
