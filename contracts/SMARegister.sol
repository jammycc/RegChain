pragma solidity >=0.4.21 <0.7.0;

import "./ASInfo.sol";

contract SMARegister {

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }

    struct ASRequest {
        address owner;
        bytes20 id;
        uint256 reqType;
        uint256 asn;
    }

    // administrator address of security aliance
    address public owner;

    // AS join request queue
    ASRequest[] private _reqs;

    // AS queue
    ASInfo[] private _ases;


    // events
    event ASRequestCreated(uint256 indexed reqType, uint256 indexed asn, address indexed id);
    event ASRequestApproved(uint256 indexed reqType, uint256 indexed asn, address indexed id);
    event ASRequestRejected(uint256 indexed reqType, uint256 indexed asn, address indexed id);
    event ASCreated(ASInfo indexed asInfo, address indexed id);
    event ASDeleted(ASInfo indexed asInfo, address indexed id);

    constructor() public {
        owner = msg.sender;
    }

    function toBytes(address x) public pure returns (bytes20) {
        bytes20 b;
        for (uint i = 0; i < 20; i++) {
            b |= bytes20(byte(uint8(uint256(x) / (2 ** (8 * (19 - i))))) & 0xFF) >> (i * 8);
        }
        return b;
    }

    function createASRequest(
        uint256 _reqType,
        uint256 _asn
    )
        public
    {
        ASRequest memory req = ASRequest(
            msg.sender,
            toBytes(msg.sender),
            _reqType,
            _asn
        );
        _reqs.push(req);
        emit ASRequestCreated(_reqType, _asn, msg.sender);
    }

    function requestQuery() public view returns (
        bytes20[] memory ids,
        uint256[] memory reqTypes,
        uint256[] memory asns)
    {
        ids = new bytes20[](_reqs.length);
        reqTypes = new uint256[](_reqs.length);
        asns = new uint256[](_reqs.length);
        for (uint256 i = 0; i < _reqs.length; ++i) {
            ids[i] = _reqs[i].id;
            reqTypes[i] = _reqs[i].reqType;
            asns[i] = _reqs[i].asn;
        }
        return (ids, reqTypes, asns);
    }

    function requestCount() public view returns (uint256) {
        return _reqs.length;
    }

    function asQuery() public view returns (ASInfo[] memory) {
        return _ases;
    }

    function asCount() public view returns (uint256) {
        return _ases.length;
    }

    function findIndexFromReqs(bytes20 id) private view returns (uint256){
        for (uint256 i = 0; i < _reqs.length; ++i) {
            if (_reqs[i].id == id) {
                return i;
            }
        }
        assert(false);
    }

    function removeFromReqs(uint256 index) private {
        for (uint256 i = index; i + 1 < _reqs.length; ++i) {
            _reqs[i] = _reqs[i + 1];
        }
        _reqs.pop();
    }

    function findIndexFromAses(bytes20 id) private view returns (uint256){
        for (uint256 i = 0; i < _ases.length; ++i) {
            if (_ases[i].id() == id) {
                return i;
            }
        }
        assert(false);
    }

    function removeFromAses(uint256 index) private {
        for (uint256 i = index; i + 1 < _ases.length; ++i) {
            _ases[i] = _ases[i + 1];
        }
        _ases.pop();
    }

    function requestApprove(bytes20 id) public onlyOwner {
        uint256 index = findIndexFromReqs(id);
        ASRequest memory req = _reqs[index];
        removeFromReqs(index);
        if (req.reqType == 0) {
            ASInfo asInfo = new ASInfo(
                req.owner,
                req.id,
                req.asn
            );
            _ases.push(asInfo);
            emit ASCreated(asInfo, req.owner);
        } else {
            index = findIndexFromAses(req.id);
            ASInfo asInfo = _ases[index];
            removeFromAses(index);
            emit ASDeleted(asInfo, req.owner);
        }
        emit ASRequestApproved(req.reqType, req.asn, req.owner);
    }

    function requestReject(bytes20 id) public onlyOwner {
        uint256 index = findIndexFromReqs(id);
        ASRequest memory req = _reqs[index];
        removeFromReqs(index);
        emit ASRequestRejected(req.reqType, req.asn, req.owner);
    }

    function singleACSQuery(uint256 asn, uint256 time) public view returns(string memory) {
        for (uint256 i = 0; i < _ases.length; ++i) {
            if (_ases[i].asn() == asn) {
                return _ases[i].getCurrentACS(time);
            }
        }
        assert(false);
    }

    /*
    function allACSQuery(uint256 time) public view returns(uint256[] memory asns, string[] memory addrs) {
        asns = new uint256[](_ases.length);
        addrs = new string[](_ases.length);
        for (uint256 i = 0; i < _ases.length; ++i) {
            asns[i] = _ases[i].asn();
            addrs[i] = _ases[i].getCurrentACS(time);
        }
        return (asns, addrs);
    }
    */
}
