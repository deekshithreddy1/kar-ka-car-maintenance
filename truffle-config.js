const HDWalletProvider = require("@truffle/hdwallet-provider");

// Use the private key from your MetaMask (ewoq key for testing)
const privateKey = "56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027";

module.exports = {
  networks: {
    localavalanche: {
      provider: () => new HDWalletProvider({
        privateKeys: [privateKey],
        providerOrUrl: "http://127.0.0.1:64596/ext/bc/ZVQNVAWZb2J3iGsVocMfHnnETJv4aBWNdEudUTEW3zuQw2Y2o/rpc"
      }),
      network_id: 17, // Replace with your ChainID (e.g., 111 from your Subnet creation)
      gas: 3000000,    // Adjust if needed
      gasPrice: 225000000000, // Default for Avalanche (225 Gwei)
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.8.29", // Match your contract's pragma
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};