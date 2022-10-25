// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    //bytes32 favw= "dog"; maximum size=32 or else there will be an error
    uint256 testnumber;

    mapping(string=>uint256) public nametotestnumber;
    struct poeple{
        uint256 testnumber;
        string name;
    }
    //uint256[] public ppl; ...this is an array 
    poeple[] public ppl;

    function store(uint256 _testnumber) public virtual{
        testnumber=_testnumber+1;
    }
    function retrieve() public view returns(uint256){
        return testnumber;
    }

    function addperson (string memory _name, uint256 _testnumber) public {
        //ppl.push(poeple(_testnumber,_name));
        /*poeple memory newperson = poeple({testnumber:_testnumber, name:_name});
        ppl.push(newperson);*/
        poeple memory newperson = poeple(_testnumber,_name);
        ppl.push(newperson);
        nametotestnumber[_name]=_testnumber;
    }
}
