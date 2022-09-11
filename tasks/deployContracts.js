// const { alphaGov, erc20comp, timelock } = require('../../helpers/compound_deploy');
// const { getExpectedContractAddress } = require('../../helpers/expected_contract');

const fs = require('fs');

task('bicheiro', "Deploys all contracts, to have a bicheiro.")
    .addParam("subscriptionId", "The subscriptionId.")
    .addParam("vrfCoordinator", "The vrfCoordinator. https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations")
    .addParam("keyHash", "The keyHash. https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations")
    .addOptionalParameter("interval","suggested 900 as 15 minutes")
    .setAction(async (taskArgs, hre) => {

        console.log("Deploying Game of Bicho");

        const signer = await hre.ethers.getSigner()

        // HARDHAT LOG
        console.log(
            `network:\x1B[36m${hre.network.name}\x1B[37m`,
            `\nsigner:\x1B[33m${signer.address}\x1B[37m\n`
        );

        ///////////////// BICHO DEPLOYMENT ///////////////////////////////
        // INFO LOGS
        console.log("token_owner:\x1B[33m", token_owner, "\x1B[37m\n");

        const Bicho = await hre.ethers.getContractFactory("Bicho");

        // constructor()
        const bicho = await Bicho.connect(signer).deploy();

        // await deploy and get block number
        await bicho.deployed();

        const blockToken = await hre.ethers.provider.getBlock("latest")

        // DEPLOYMENT LOGS
        console.log(`Bicho deployed to:\x1B[33m`, bicho.address, "\x1B[37m");
        console.log(`Creation block number:`, blockToken.number);

        // verify cli
        const verify_str_token = `npx hardhat verify ` +
            `--network ${network.name} ` +
            `${bicho.address} `
        console.log("\n" + verify_str_token)
        // save it to a file to make sure the user doesn't lose it.
        fs.appendFileSync('contracts.out', `${new Date()}\b Bicho contract deployed at: ${bicho.address}\n${verify_str_token}\n\n`);

        ///////////////// RandomNumberConsumer DEPLOYMENT ///////////////////////////

        const subscriptionId = taskArgs.subscriptionId;
        const vrfCoordinator = taskArgs.vrfCoordinator;
        const keyHash = taskArgs.keyHash;
    
        // INFO LOGS
        console.log("subscriptionId",subscriptionId)
        console.log("vrfCoordinator",vrfCoordinator)
        console.log("keyHash",keyHash)

        const RandomNumberConsumerV2 = await hre.ethers.getContractFactory("RandomNumberConsumerV2");

        // constructor()
        const random = await RandomNumberConsumerV2.connect(signer).deploy(
            subscriptionId,
            vrfCoordinator,
            keyHash
        );

        const block = await hre.ethers.provider.getBlock("latest")

        // DEPLOYMENT LOGS
        console.log(`Consumer deployed to:\x1B[33m`, random.address, "\x1B[37m");
        console.log(`Creation block number:\x1B[35m`, block.number, "\x1B[37m");

        // verify cli command
        const verify_consumer = `npx hardhat verify ` +
            `--network ${network.name} ` +
            `${random.address} ` +
            `"${subscriptionId}" "${vrfCoordinator}" "${keyHash}"`

        console.log("\n" + verify_consumer)

        // save it to a file to make sure the user doesn't lose it.
        fs.appendFileSync('contracts.out', `${new Date()}\nConsumer contract deployed at: ${random.address}\n${verify_consumer}\n\n`);

        ///////////////// GOVERNANCE DEPLOYMENT ///////////////////////////
        // GOVERNANCE DATA
        const random_address = random.address;
        const bicho_address = bicho.address;
        // GOVERNANCE DATA
        console.log("random_address", random.address);
        console.log("bicho_address", bicho.address);
        const interval = taskArgs.interval ? taskArgs.interval : "900";
        console.log("interval", interval);

        // DEPLOY KEEPER
        const KeepersCounter = await hre.ethers.getContractFactory("KeepersCounter");

        // constructor( uint256 updateInterval, address _s_owner,address _vrfConsumer,address _Bicho)

        const keeper = await KeepersCounter.connect(signer).deploy(
            interval,
            signer.address,
            random_address,
            bicho_address
        );

        // await deploy and get block number
        await keeper.deployed();

        const govBlock = await hre.ethers.provider.getBlock("latest")

        // DEPLOYMENT LOGS
        console.log(`Keeper deployed to:\x1B[33m`, keeper.address, "\x1B[37m");
        console.log(`Creation block number:\x1B[35m`, govBlock.number, "\x1B[37m");

        // verify cli
        const verify_bicheiro_hackaton = `npx hardhat verify ` +
            `--network ${network.name} ` +
            `${keeper.address} ` +
            `"${interval}" "${signer.address}" "${random_address}" "${bicho_address}"`

        console.log("\n" + verify_bicheiro_hackaton)

        // save it to a file to make sure the user doesn't lose it.
        fs.appendFileSync('contracts.out', `${new Date()}\n Keeper contract deployed at: ${keeper.address}\n${verify_bicheiro_hackaton}\n\n`);
        
        const tx = await bicho.setKeeper(keeper.address);
        const receipt = await tx.wait()
        console.log("receipt",receipt)
    });