// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

// https://docs.soliditylang.org/en/breaking/080-breaking-changes.html#silent-changes-of-the-semantics
contract Calc128 {

    uint128 public a;
    
    function set(uint128 b) public { a  = b; }
    function add(uint128 b) public { a += b; }
    function sub(uint128 b) public { a -= b; }
    function mul(uint128 b) public { a *= b; }
    function div(uint128 b) public { a /= b; }

}
