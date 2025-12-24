// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
//pragma experimental ABIEncoderV2;
import "hardhat/console.sol";

contract ScamStore {
    struct Scam{
        uint16 ScamType;//phishing etc.
        uint16 ScamMethod;//phone, email, etc
        string Sender;//phone number, email address
        uint32 Seen;//number of times seen
        uint32 Disputed;//number of times disputed
        address payable OriginalSubmiter;
        uint256 ScamID;
    }

    //address payable private StorageWallet = payable(address(this));

    mapping(uint256 => Scam) private Scams;
     
    function AddScam(Scam memory NewScam) private {
        Scams[NewScam.ScamID] = NewScam;
    }

    function CalcHash(uint16 Scamtype, uint16 ScamMethod, string calldata Sender) private pure returns (uint32 Hash) {
        //get a better hash function later
        bytes memory SenderB = bytes(Sender);
        uint32 SenderQ = 0;//quantity of the sender bytes, added together
        for(uint c = 0; c < SenderB.length; c++){
            SenderQ += uint8(SenderB[c]);
        }
        //now we have 3 uints, and can do math on them
        Hash = SenderQ + (uint32(Scamtype) * uint32(ScamMethod));

    }

    function CheckScam(uint16 Scamtype, uint16 ScamMethod, string calldata Sender) public view returns (bool present){
        uint Hash = CalcHash(Scamtype,ScamMethod,Sender);
        if (Scams[Hash].Seen != 0) {
            present = true;
        }
        else{
            present = false;
        }
    }

    function ReportScam(uint16 Scamtype, uint16 ScamMethod, string calldata Sender) payable public {
        uint Hash = CalcHash(Scamtype,ScamMethod,Sender);
        uint seen = Scams[Hash].Seen;
        uint disp = 1;
        console.log(Hash);
        console.log(Scams[Hash].Seen);
        console.log(Scams[Hash].Disputed);
        if(Scams[Hash].Disputed > disp){
            disp = Scams[Hash].Disputed;
        }
        if(CheckScam(Scamtype,ScamMethod,Sender)){
            Scams[Hash].Seen++;
            console.log("Incrementing");
            if(seen/disp > 5){
                uint256 deposit = msg.value / 5;
                console.log("paying ");
                console.log(Scams[Hash].OriginalSubmiter);
                Scams[Hash].OriginalSubmiter.transfer(deposit);
                //require(sent,"error in payout");
            //Scams[CalcHash(Scamtype, ScamMethod, Sender)].OriginalSubmiter.recieve(deposit);
        }
        }
        else{
            Scam memory NS = Scam({
                ScamType:Scamtype,
                ScamMethod:ScamMethod,
                Sender:Sender,
                Seen:1,
                Disputed:0,
                ScamID:Hash,
                OriginalSubmiter:payable(msg.sender)
            
            });
            AddScam(NS);
        }

        //console.log(Scams[Hash]);
        
        
    }

    function DisputeScam(uint16 Scamtype, uint16 ScamMethod, string calldata Sender) public {
        uint256 Hash = CalcHash(Scamtype, ScamMethod, Sender);
        require (CheckScam(Scamtype,ScamMethod,Sender), "Scam not found");
        Scams[Hash].Disputed++;
    }

    function GetStats(uint16 Scamtype, uint16 ScamMethod, string calldata Sender) public view returns (uint32, uint32){
        require(CheckScam(Scamtype, ScamMethod, Sender),"No scam has been reported with these details yet");
        uint256 Hash = CalcHash(Scamtype, ScamMethod, Sender);
        return (Scams[Hash].Seen,Scams[Hash].Disputed);
    }

    //REWARD MECHANISM -- GIVE A PORTION BACK IF YOUR INITIAL REPORT GETS A BUNCH OF CONFIRMATIONS
    //--GIVE SOME TO CASSANDRA AND WEB PAGE HOSTS

}

