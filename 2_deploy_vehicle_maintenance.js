const VehicleMaintenance = artifacts.require("VehicleMaintenance");
const RegisterCar = artifacts.require("RegisterCar");

module.exports = async function (deployer) {
    const registerCar = await RegisterCar.deployed();
    await deployer.deploy(VehicleMaintenance, registerCar.address);
};