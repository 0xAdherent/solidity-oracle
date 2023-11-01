// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Oracle {

    event SetOwner(
        address indexed oldOwner, 
        address newOwner
    );
    event SetFeeder(
        address indexed admin, 
        address feeder, 
        bool valid
    );
    event SetUpdateInterval(
        address indexed admin, 
        uint64 interval
    );
    event RegisterTokenPrice(
        address indexed admin, 
        uint8 indexed tid, 
        uint256 price, 
        uint256 timestamp
    );
    event UpdateTokenPrice(
        address indexed feeder,
        uint8 indexed tid, 
        uint256 price, 
        uint256 timestamp    
    );    
    event UpdateTokenPriceBatch(
        address indexed feeder,
        uint8[] tids, 
        uint256[] prices, 
        uint256[] timestamps   
    );  

    struct Price {
        uint256 value;
        uint8 decimal;
        uint256 timestamp;
    }

    address public owner;
    mapping (address => bool) feeders;
    mapping (uint8 => bool) pairs;
    mapping (uint8 => Price) priceOracles;
    uint64 public  updateInterval;


	constructor(uint64 _interval) {
        owner = msg.sender;
        updateInterval = _interval;
	}
	
    function setOwner(address _owner) external {
        require(msg.sender == owner, 'not owner');
        require(_owner != address(0x0), 'owner address error');

        owner = _owner;
        emit SetOwner(msg.sender, _owner);
    }
    
    function setFeeder(
        address _feeder,
        bool _valid
        ) external {
        require(msg.sender == owner, 'not owner');
        require(_feeder != address(0x0), 'feeder address error');  

        feeders[_feeder] = _valid;
        emit SetFeeder(msg.sender, _feeder, _valid);      
    }

    function setUpdateInterval(
        uint64 _interval
    ) external {
        require(msg.sender == owner, 'not owner');

        updateInterval = _interval;
        emit SetUpdateInterval(msg.sender, _interval);
    }

    function registerTokenPrice(
        uint8 _tid,
        uint256 _tokenPrice,
        uint8 _priceDecimal
    ) external {
        require(msg.sender == owner, 'not owner');

        require(!pairs[_tid], 'token existed');
        require(_tokenPrice > 0, 'token price error');

        Price memory p = Price({
            value: _tokenPrice,
            decimal: _priceDecimal,
            timestamp: block.timestamp
        });
        priceOracles[_tid] = p;
        pairs[_tid] = true;
        emit RegisterTokenPrice(msg.sender, _tid, _tokenPrice, block.timestamp);
    }

    function updateTokenPrice(
        uint8 _tid,
        uint256 _tokenPrice,
        uint256 _timestamp
    ) external {
        require(feeders[msg.sender], 'not feeder');
        require(pairs[_tid], 'token not existed');
        require(_tokenPrice > 0, 'token price error');
        require(block.timestamp <= _timestamp + updateInterval, 'timestamp error');

        Price storage p = priceOracles[_tid];
        p.value = _tokenPrice;
        p.timestamp = _timestamp;
        emit UpdateTokenPrice(msg.sender, _tid, _tokenPrice, _timestamp);
    }

    function updateTokenPriceBatch(
        uint8[] calldata _tids,
        uint256[] calldata _tokenPrices,
        uint256[] calldata _timestamps
    ) external {
        require(feeders[msg.sender], 'not feeder');
        uint256 len = _tids.length;
        require(len > 0 && len == _tokenPrices.length && len == _timestamps.length, 'bad ids & prices & ts len');

        for(uint256 i = 0; i < len; i++) {
            uint8 tid = _tids[i];
            uint256 price = _tokenPrices[i];
            uint256 timestamp = _timestamps[i];

            require(pairs[tid], 'token not existed');
            require(price > 0, 'token price error');
            require(block.timestamp <= timestamp + updateInterval, 'timestamp error');

            Price storage p = priceOracles[tid];
            p.value = price;
            p.timestamp = timestamp;
        }

        emit UpdateTokenPriceBatch(msg.sender, _tids, _tokenPrices, _timestamps);

    }

    function getTokenPrice(uint8 _tid) public view returns (bool, uint256, uint8) {
        Price memory p = priceOracles[_tid];
        return(pairs[_tid], p.value, p.decimal);
    }
    
}