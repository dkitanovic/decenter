//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {IWETH} from "@aave/protocol-v2/contracts/misc/interfaces/IWETH.sol";
import {IAToken} from "@aave/protocol-v2/contracts/interfaces/IAToken.sol";
import {Ownable} from "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract Bank is Ownable{

    using SafeMath for uint256;

    ILendingPoolAddressesProvider private provider = ILendingPoolAddressesProvider(address(0x88757f2f99175387aB4C6a4b3067c77A695b0349));
    IWETH private WETH = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    ILendingPool private POOL;
    IAToken private aWETH;
    uint256 private timestamp;
    uint256 private numberOfUsers;
    uint256 private totalBalance;

    struct UserInfo {
        uint256 balance;
        uint256 time;
    }
    mapping(address => UserInfo) private info;
    mapping(uint => address) private indexes;

    constructor(uint256 _timestamp) public {
        address pool_address = provider.getLendingPool();
        POOL = ILendingPool(pool_address);
        aWETH = IAToken(POOL.getReserveData(address(WETH)).aTokenAddress);
        WETH.approve(pool_address, uint256(-1));
        aWETH.approve(pool_address, uint256(-1));
        timestamp = _timestamp;
        numberOfUsers = 0;
        totalBalance = 0;
    }

    function depositMyETH() external payable {
        uint256 amount = msg.value;
        address user = msg.sender;

        if (info[user].time == 0x0){
            indexes[numberOfUsers] = user;            
            info[user].balance = amount;
            numberOfUsers = numberOfUsers.add(1);
        } 
        else
            info[user].balance = info[user].balance.add(amount);

        info[user].time = now;        
        WETH.deposit{value: amount}();
        POOL.deposit(address(WETH), amount, address(this), 0);
        totalBalance = totalBalance.add(amount);
    }

    function withdrawMyETH() external {
        address user = msg.sender;
        require(info[user].balance != 0x0, "You don't have any ETH on contract!!!");

        uint256 amount;
        uint256 penalty = 0;
        if (now >= info[user].time + timestamp)
            amount = info[user].balance;
        else {
            uint256 minimum = info[user].balance.div(2);
            uint256 time_passed = now.sub(info[user].time);
            uint256 aboveMinimum = (minimum.mul(time_passed)).div(timestamp);  
            
            amount = minimum.add(aboveMinimum);
            uint256 maximumLoss = info[user].balance.sub(amount);

            uint256 totalOfOthers = totalBalance.sub(info[user].balance);
            for (uint i=0; i < numberOfUsers; i++)
                if (indexes[i] != user){
                    uint256 toAdd = (maximumLoss.mul(info[indexes[i]].balance)).div(totalOfOthers);
                    info[indexes[i]].balance = info[indexes[i]].balance.add(toAdd);
                    penalty = penalty.add(toAdd);
                }
        }

        POOL.withdraw(address(WETH), amount, address(this));
        WETH.withdraw(amount);
        address payable to = msg.sender;
        to.transfer(amount);
        
        totalBalance = totalBalance.sub(info[user].balance.sub(penalty));
        info[user].balance = 0;
    }

    function claimRewards() external onlyOwner{
        uint256 profit = aWETH.balanceOf(address(this)).sub(totalBalance);
        POOL.withdraw(address(WETH), profit, address(this));
        WETH.withdraw(profit);
        address payable to = msg.sender;
        to.transfer(profit);
    }

    receive() external payable {}

}
