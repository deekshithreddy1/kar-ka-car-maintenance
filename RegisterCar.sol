// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract RegisterCar {
    // Struct for car details
    struct Car {
        string vin;
        string carMake;
        string carModel;
        string carColor;
        uint256 carYear;
        address owner;
        bool isActive;
    }

    // Mapping: VIN => Car details
    mapping(string => Car) public registeredCars;

    // Array to store all VINs
    string[] private allVins;

    // Events
    event CarRegistered(string vin, address owner);
    event CarTransferred(string vin, address from, address to);
    event CarUpdated(string vin, address owner);
    event CarDeleted(string vin, address owner);

    // Modifier: Only car owner can perform action
    modifier onlyCarOwner(string memory _vin) {
        require(registeredCars[_vin].owner == msg.sender, "Not the car owner");
        require(registeredCars[_vin].isActive, "Car is not active");
        _;
    }

    // Function to register a car
    function registerCar(
        string memory _vin,
        string memory _carMake,
        string memory _carModel,
        string memory _carColor,
        uint256 _carYear
    ) public {
        // Validate inputs
        require(bytes(_vin).length == 17, "Invalid VIN length");
        require(bytes(_carMake).length > 0, "Car make cannot be empty");
        require(bytes(_carModel).length > 0, "Car model cannot be empty");
        require(bytes(_carColor).length > 0, "Car color cannot be empty");
        require(
            _carYear >= 1900 && _carYear <= block.timestamp,
            "Invalid car year"
        );

        // Check if VIN is already registered
        require(
            registeredCars[_vin].owner == address(0),
            "VIN already registered"
        );

        // Register the car with the caller's address as owner
        registeredCars[_vin] = Car({
            vin: _vin,
            carMake: _carMake,
            carModel: _carModel,
            carColor: _carColor,
            carYear: _carYear,
            owner: msg.sender,
            isActive: true
        });

        // Add VIN to the array
        allVins.push(_vin);

        emit CarRegistered(_vin, msg.sender);
    }

    // Function to transfer car ownership
    function transferCarOwnership(
        string memory _vin,
        address _newOwner
    ) public onlyCarOwner(_vin) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");

        address oldOwner = registeredCars[_vin].owner;
        registeredCars[_vin].owner = _newOwner;

        emit CarTransferred(_vin, oldOwner, _newOwner);
    }

    // Function to update car details
    function updateCarDetails(
        string memory _vin,
        string memory _carColor,
        uint256 _carYear
    ) public onlyCarOwner(_vin) {
        require(bytes(_carColor).length > 0, "Car color cannot be empty");
        require(
            _carYear >= 1900 && _carYear <= block.timestamp,
            "Invalid car year"
        );

        Car storage car = registeredCars[_vin];
        car.carColor = _carColor;
        car.carYear = _carYear;

        emit CarUpdated(_vin, msg.sender);
    }

    // Function to delete car registration
    function deleteCarRegistration(
        string memory _vin
    ) public onlyCarOwner(_vin) {
        registeredCars[_vin].isActive = false;
        emit CarDeleted(_vin, msg.sender);
    }

    // Function to get car details (for verification)
    function getCarDetails(
        string memory _vin
    )
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            address
        )
    {
        Car memory car = registeredCars[_vin];
        require(car.owner != address(0), "Car not registered");
        require(car.isActive, "Car is not active");
        return (
            car.vin,
            car.carMake,
            car.carModel,
            car.carColor,
            car.carYear,
            car.owner
        );
    }

    // Function to get all registered vehicles
    function getAllVehicles() public view returns (string[] memory) {
        return allVins;
    }
}
