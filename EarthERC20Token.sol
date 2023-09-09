pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EarthERC20Token is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant CAN_MINT = keccak256("CAN_MINT");

    constructor() ERC20("Earth", "EARTH") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint256 _amount) external {
        if (!hasRole(CAN_MINT, msg.sender)) {
            revert("Caller cannot mint");
        }
        _mint(_to, _amount);
    }

    function addMinter(address _account) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller must be admin"
        );
        _grantRole(CAN_MINT, _account);
    }

    function removeMinter(address _account) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller must be admin"
        );
        _revokeRole(CAN_MINT, _account);
    }
}
