// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IRegisterCar {
    function getCarDetails(
        string memory _vin
    )
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            address
        );
}

interface IVehicleMaintenance {
    function getRecordCount(string memory _vin) external view returns (uint256);
    function getRecord(
        string memory _vin,
        uint256 _index
    )
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory,
            uint256,
            address
        );
}

contract VehicleMaintenance is IVehicleMaintenance {
    // Struct for maintenance record
    struct MaintenanceRecord {
        address mechanicAddress; // Address of the mechanic who performed the maintenance
        string vehicleVin; // Vehicle Identification Number
        uint256 vehicleMileage; // Current mileage of the vehicle
        string beforeDescription; // Description of the vehicle before maintenance
        string afterDescription; // Description of the vehicle after maintenance
        string partsUsed; // List of parts used in maintenance
        uint256 timestamp; // Timestamp of when the maintenance was recorded
    }

    // Mapping: VIN => array of maintenance records
    mapping(string => MaintenanceRecord[]) public maintenanceRecords;

    // Authorized mechanics
    mapping(address => bool) public authorizedMechanics;

    // Reference to RegisterCar contract
    IRegisterCar public registerCar;

    // Contract owner (for managing mechanics)
    address public owner;

    // Events
    event MaintenanceAdded(
        string vin,
        address mechanicAddress,
        uint256 vehicleMileage,
        string beforeDescription,
        string afterDescription,
        string partsUsed,
        uint256 timestamp
    );
    event MaintenanceUpdated(string vin, uint256 index, uint256 mileage);
    event MaintenanceDeleted(string vin, uint256 index);
    event MechanicAdded(address mechanic);
    event MechanicRemoved(address mechanic);

    constructor(address _registerCarAddress) {
        require(
            _registerCarAddress != address(0),
            "Invalid RegisterCar address"
        );
        owner = msg.sender;
        registerCar = IRegisterCar(_registerCarAddress);
    }

    // Modifier: Only owner can add mechanics
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    // Modifier: Only authorized mechanics can add records
    modifier onlyMechanic() {
        require(
            authorizedMechanics[msg.sender],
            "Only authorized mechanics can add records"
        );
        _;
    }

    // Add a mechanic (only owner)
    function addMechanic(address _mechanic) public onlyOwner {
        require(_mechanic != address(0), "Invalid mechanic address");
        require(!authorizedMechanics[_mechanic], "Mechanic already authorized");
        authorizedMechanics[_mechanic] = true;
        emit MechanicAdded(_mechanic);
    }

    // Remove a mechanic (only owner)
    function removeMechanic(address _mechanic) public onlyOwner {
        require(authorizedMechanics[_mechanic], "Mechanic not authorized");
        authorizedMechanics[_mechanic] = false;
        emit MechanicRemoved(_mechanic);
    }

    // Add maintenance record
    function addMaintenance(
        string memory _vin,
        uint256 _vehicleMileage,
        string memory _beforeDescription,
        string memory _afterDescription,
        string memory _partsUsed
    ) public onlyMechanic {
        require(bytes(_vin).length > 0, "VIN cannot be empty");
        require(
            bytes(_beforeDescription).length > 0,
            "Before description cannot be empty"
        );
        require(
            bytes(_afterDescription).length > 0,
            "After description cannot be empty"
        );

        // Verify VIN is registered
        (, , , , , address carOwner) = registerCar.getCarDetails(_vin);
        require(carOwner != address(0), "VIN not registered");

        // Validate mileage is greater than previous record
        uint256 recordCount = maintenanceRecords[_vin].length;
        if (recordCount > 0) {
            MaintenanceRecord memory lastRecord = maintenanceRecords[_vin][
                recordCount - 1
            ];
            require(
                _vehicleMileage > lastRecord.vehicleMileage,
                "Mileage must be greater than previous record"
            );
            require(
                block.timestamp > lastRecord.timestamp,
                "Timestamp must be greater than previous record"
            );
        }

        MaintenanceRecord memory record = MaintenanceRecord({
            mechanicAddress: msg.sender,
            vehicleVin: _vin,
            vehicleMileage: _vehicleMileage,
            beforeDescription: _beforeDescription,
            afterDescription: _afterDescription,
            partsUsed: _partsUsed,
            timestamp: block.timestamp
        });

        maintenanceRecords[_vin].push(record);
        emit MaintenanceAdded(
            _vin,
            msg.sender,
            _vehicleMileage,
            _beforeDescription,
            _afterDescription,
            _partsUsed,
            block.timestamp
        );
    }

    // Update maintenance record
    function updateMaintenance(
        string memory _vin,
        uint256 _index,
        uint256 _mileage,
        string memory _beforeDescription,
        string memory _afterDescription,
        string memory _partsUsed
    ) public onlyMechanic {
        require(
            _index < maintenanceRecords[_vin].length,
            "Index out of bounds"
        );
        require(
            bytes(_beforeDescription).length > 0,
            "Before description cannot be empty"
        );
        require(
            bytes(_afterDescription).length > 0,
            "After description cannot be empty"
        );

        MaintenanceRecord storage record = maintenanceRecords[_vin][_index];
        record.vehicleMileage = _mileage;
        record.beforeDescription = _beforeDescription;
        record.afterDescription = _afterDescription;
        record.partsUsed = _partsUsed;
        record.timestamp = block.timestamp;

        emit MaintenanceUpdated(_vin, _index, _mileage);
    }

    // Delete maintenance record
    function deleteMaintenance(
        string memory _vin,
        uint256 _index
    ) public onlyMechanic {
        require(
            _index < maintenanceRecords[_vin].length,
            "Index out of bounds"
        );

        // Shift all records after the deleted one to the left
        for (uint256 i = _index; i < maintenanceRecords[_vin].length - 1; i++) {
            maintenanceRecords[_vin][i] = maintenanceRecords[_vin][i + 1];
        }
        maintenanceRecords[_vin].pop();

        emit MaintenanceDeleted(_vin, _index);
    }

    // Get record count for a VIN
    function getRecordCount(string memory _vin) public view returns (uint256) {
        return maintenanceRecords[_vin].length;
    }

    // Get a specific record
    function getRecord(
        string memory _vin,
        uint256 _index
    )
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory,
            uint256,
            address
        )
    {
        require(
            _index < maintenanceRecords[_vin].length,
            "Index out of bounds"
        );
        MaintenanceRecord memory record = maintenanceRecords[_vin][_index];
        return (
            record.vehicleMileage,
            record.beforeDescription,
            record.afterDescription,
            record.partsUsed,
            record.timestamp,
            record.mechanicAddress
        );
    }
}
