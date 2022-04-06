const hre = require("hardhat");
const fs = require("fs");

const LendingPoolV2Artifact = require('@aave/protocol-v2/artifacts/contracts/protocol/lendingpool/LendingPool.sol/LendingPool.json');

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Bank = await ethers.getContractFactory("Bank");
    const bank = await Bank.deploy(600);
  
    console.log("Bank address:", bank.address);

    const data = {
        address: bank.address,
        abi: JSON.parse(bank.interface.format('json'))
    };
    fs.writeFileSync('frontend/src/Bank.json', JSON.stringify(data));
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  