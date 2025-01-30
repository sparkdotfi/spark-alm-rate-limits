// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import { CCTPForwarder } from "xchain-helpers/src/forwarders/CCTPForwarder.sol";

import { Base }     from "spark-address-registry/src/Base.sol";
import { Ethereum } from "spark-address-registry/src/Ethereum.sol";

import { ForeignController } from "spark-alm-controller/src/ForeignController.sol";
import { MainnetController } from "spark-alm-controller/src/MainnetController.sol";
import { RateLimits }        from "spark-alm-controller/src/RateLimits.sol";
import { RateLimitHelpers }  from "spark-alm-controller/src/RateLimitHelpers.sol";

contract MainnetRateLimitTests is Test {

    address constant public AAVE_PRIME_USDS_ATOKEN = 0x09AA30b182488f769a9824F15E6Ce58591Da4781;
    address constant public SPARKLEND_USDS_ATOKEN  = 0xC02aB1A5eaA8d1B114EF786D9bde108cD4364359;

    RateLimits        rateLimits = RateLimits(Ethereum.ALM_RATE_LIMITS);
    MainnetController controller = MainnetController(Ethereum.ALM_CONTROLLER);

    bytes32 susdeCooldown;
    bytes32 usdcToBaseCctp;
    bytes32 usdcToCctp;
    bytes32 usdeBurn;
    bytes32 usdeMint;
    bytes32 usdsMint;
    bytes32 usdsToUsdc;

    bytes32 depositSUsde;
    bytes32 depositSUsds;
    bytes32 withdrawSUsds;

    bytes32 depositAavePrimeUSDS;
    bytes32 withdrawAavePrimeUSDS;

    bytes32 depositSparkLendUSDC;
    bytes32 depositSparkLendUSDS;
    bytes32 withdrawSparkLendUSDC;
    bytes32 withdrawSparkLendUSDS;

    function setUp() public {
        vm.createSelectFork(getChain("mainnet").rpcUrl);

        susdeCooldown = controller.LIMIT_SUSDE_COOLDOWN();
        usdcToCctp    = controller.LIMIT_USDC_TO_CCTP();
        usdeBurn      = controller.LIMIT_USDE_BURN();
        usdeMint      = controller.LIMIT_USDE_MINT();
        usdsMint      = controller.LIMIT_USDS_MINT();
        usdsToUsdc    = controller.LIMIT_USDS_TO_USDC();

        usdcToBaseCctp = RateLimitHelpers.makeDomainKey(
            controller.LIMIT_USDC_TO_DOMAIN(),
            CCTPForwarder.DOMAIN_ID_CIRCLE_BASE
        );

        bytes32 deposit4626  = controller.LIMIT_4626_DEPOSIT();
        bytes32 withdraw4626 = controller.LIMIT_4626_WITHDRAW();
        bytes32 depositAave  = controller.LIMIT_AAVE_DEPOSIT();
        bytes32 withdrawAave = controller.LIMIT_AAVE_WITHDRAW();

        // NOTE: `susdeCooldown` captures withdraw case
        depositSUsde  = RateLimitHelpers.makeAssetKey(deposit4626,  Ethereum.SUSDE);
        // depositSUsds  = RateLimitHelpers.makeAssetKey(deposit4626,  Ethereum.SUSDS);
        // withdrawSUsds = RateLimitHelpers.makeAssetKey(withdraw4626, Ethereum.SUSDS);

        depositAavePrimeUSDS = RateLimitHelpers.makeAssetKey(depositAave, AAVE_PRIME_USDS_ATOKEN);
        depositSparkLendUSDC = RateLimitHelpers.makeAssetKey(depositAave, Ethereum.USDC_ATOKEN);
        depositSparkLendUSDS = RateLimitHelpers.makeAssetKey(depositAave, SPARKLEND_USDS_ATOKEN);

        withdrawAavePrimeUSDS = RateLimitHelpers.makeAssetKey(withdrawAave, AAVE_PRIME_USDS_ATOKEN);
        withdrawSparkLendUSDC = RateLimitHelpers.makeAssetKey(withdrawAave, Ethereum.USDC_ATOKEN);
        withdrawSparkLendUSDS = RateLimitHelpers.makeAssetKey(withdrawAave, SPARKLEND_USDS_ATOKEN);
    }

    function test_printMainnetKeys() public view {
        console.log("Mainnet non asset/domain based RateLimits keys:");
        logKey("LIMIT_SUSDE_COOLDOWN", susdeCooldown);
        logKey("LIMIT_USDC_TO_CCTP  ", usdcToCctp);
        logKey("LIMIT_USDE_BURN     ", usdeBurn);
        logKey("LIMIT_USDE_MINT     ", usdeMint);
        logKey("LIMIT_USDS_MINT     ", usdsMint);
        logKey("LIMIT_USDS_TO_USDC  ", usdsToUsdc);

        console.log("\nMainnet domain-based RateLimits keys:");
        logKey("LIMIT_USDC_TO_DOMAIN - Base", usdcToBaseCctp);

        console.log("\nMainnet asset-based RateLimits keys:");
        logKey("LIMIT_4626_DEPOSIT  - sUSDe          ", depositSUsde);
        // logKey("LIMIT_4626_DEPOSIT  - sUSDS          ", depositSUsds);
        // logKey("LIMIT_4626_WITHDRAW - sUSDS          ", withdrawSUsds);
        logKey("LIMIT_AAVE_DEPOSIT  - AAVE Prime USDC", depositAavePrimeUSDS);
        logKey("LIMIT_AAVE_DEPOSIT  - SparkLend USDC ", depositSparkLendUSDC);
        logKey("LIMIT_AAVE_DEPOSIT  - SparkLend USDS ", depositSparkLendUSDS);
        logKey("LIMIT_AAVE_WITHDRAW - AAVE Prime USDC", withdrawAavePrimeUSDS);
        logKey("LIMIT_AAVE_WITHDRAW - SparkLend USDC ", withdrawSparkLendUSDC);
        logKey("LIMIT_AAVE_WITHDRAW - SparkLend USDS ", withdrawSparkLendUSDS);
    }

    function logKey(string memory name, bytes32 key) public view {
        require(rateLimits.getRateLimitData(key).maxAmount > 0, "RateLimit key not found");
        console.log(name, vm.toString(key));
    }

}

contract BaseRateLimitTests is Test {

    address internal constant ATOKEN_USDC       = 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB;
    address internal constant MORPHO_SPARK_USDC = 0x7BfA7C4f149E7415b73bdeDfe609237e29CBF34A;

    RateLimits        rateLimits = RateLimits(Base.ALM_RATE_LIMITS);
    ForeignController controller = ForeignController(Base.ALM_CONTROLLER);

    bytes32 usdcToCctp;
    bytes32 usdcToEthereumCctp;

    bytes32 susdsPsmDeposit;
    bytes32 susdsPsmWithdraw;
    bytes32 usdcPsmDeposit;
    bytes32 usdcPsmWithdraw;
    bytes32 usdsPsmDeposit;
    bytes32 usdsPsmWithdraw;

    bytes32 depositAaveUSDC;
    bytes32 withdrawAaveUSDC;

    bytes32 depositMorphoSparkUSDC;
    bytes32 withdrawMorphoSparkUSDC;

    function setUp() public {
        vm.createSelectFork(getChain("base").rpcUrl);

        usdcToCctp = controller.LIMIT_USDC_TO_CCTP();

        usdcToEthereumCctp = RateLimitHelpers.makeDomainKey(
            controller.LIMIT_USDC_TO_DOMAIN(),
            CCTPForwarder.DOMAIN_ID_CIRCLE_ETHEREUM
        );

        bytes32 deposit4626  = controller.LIMIT_4626_DEPOSIT();
        bytes32 withdraw4626 = controller.LIMIT_4626_WITHDRAW();
        bytes32 depositAave  = controller.LIMIT_AAVE_DEPOSIT();
        bytes32 withdrawAave = controller.LIMIT_AAVE_WITHDRAW();
        bytes32 depositPsm   = controller.LIMIT_PSM_DEPOSIT();
        bytes32 withdrawPsm  = controller.LIMIT_PSM_WITHDRAW();

        susdsPsmDeposit  = RateLimitHelpers.makeAssetKey(depositPsm,  Base.SUSDS);
        susdsPsmWithdraw = RateLimitHelpers.makeAssetKey(withdrawPsm, Base.SUSDS);
        usdcPsmDeposit   = RateLimitHelpers.makeAssetKey(depositPsm,  Base.USDC);
        usdcPsmWithdraw  = RateLimitHelpers.makeAssetKey(withdrawPsm, Base.USDC);
        usdsPsmDeposit   = RateLimitHelpers.makeAssetKey(depositPsm,  Base.USDS);
        usdsPsmWithdraw  = RateLimitHelpers.makeAssetKey(withdrawPsm, Base.USDS);

        depositAaveUSDC  = RateLimitHelpers.makeAssetKey(depositAave,  ATOKEN_USDC);
        withdrawAaveUSDC = RateLimitHelpers.makeAssetKey(withdrawAave, ATOKEN_USDC);

        depositMorphoSparkUSDC  = RateLimitHelpers.makeAssetKey(deposit4626,  MORPHO_SPARK_USDC);
        withdrawMorphoSparkUSDC = RateLimitHelpers.makeAssetKey(withdraw4626, MORPHO_SPARK_USDC);
    }

    function test_printBaseKeys() public view {
        console.log("Base non asset/domain based RateLimits keys:");
        logKey("LIMIT_USDC_TO_CCTP", usdcToCctp);

        console.log("\nBase domain-based RateLimits keys:");
        logKey("LIMIT_USDC_TO_DOMAIN - Ethereum", usdcToEthereumCctp);

        console.log("\nBase asset-based RateLimits keys:");
        logKey("LIMIT_4626_DEPOSIT  - Morpho Spark USDC", depositMorphoSparkUSDC);
        logKey("LIMIT_4626_WITHDRAW - Morpho Spark USDC", withdrawMorphoSparkUSDC);

        console.log("");
        logKey("LIMIT_AAVE_DEPOSIT  - Aave USDC", depositAaveUSDC);
        logKey("LIMIT_AAVE_WITHDRAW - Aave USDC", withdrawAaveUSDC);

        console.log("");
        logKey("LIMIT_PSM_DEPOSIT   - sUSDS", susdsPsmDeposit);
        logKey("LIMIT_PSM_WITHDRAW  - sUSDS", susdsPsmWithdraw);
        logKey("LIMIT_PSM_DEPOSIT   - USDC ", usdcPsmDeposit);
        logKey("LIMIT_PSM_WITHDRAW  - USDC ", usdcPsmWithdraw);
        logKey("LIMIT_PSM_DEPOSIT   - USDS ", usdsPsmDeposit);
        logKey("LIMIT_PSM_WITHDRAW  - USDS ", usdsPsmWithdraw);
    }

    function logKey(string memory name, bytes32 key) public view {
        require(rateLimits.getRateLimitData(key).maxAmount > 0, "RateLimit key not found");
        console.log(name, vm.toString(key));
    }

}
