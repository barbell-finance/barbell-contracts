// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

// https://docs.soliditylang.org/en/breaking/080-breaking-changes.html#silent-changes-of-the-semantics
contract Calc256 {

    uint256 public a;
    
    function set(uint256 b) public { a  = b; }
    function add(uint256 b) public { a += b; }
    function sub(uint256 b) public { a -= b; }
    function mul(uint256 b) public { a *= b; }
    function div(uint256 b) public { a /= b; }

}
