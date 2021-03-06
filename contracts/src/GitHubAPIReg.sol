/** 
 * GitHubAPIReg.sol 
 * Abstract Logic for GitHubOracle Registries.
 * Ricardo Guilherme Schmidt <3esmit@gmail.com>
 */
import "Owned.sol";
import "oraclizeAPI_0.4.sol";
import "strings.sol";

pragma solidity ^0.4.11;

contract GitHubAPIReg is Owned, usingOraclize {
    using strings for string;
    using strings for strings.slice;
    
    string cred = "";

    event OracleEvent(bytes32 myid, string result, bytes proof);
    
    function GitHubAPIReg(){
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }

    //owner management
    function setAPICredentials(string _client_id, string _client_secret) only_owner {
        strings.slice [] memory cm = new strings.slice[](5);
        cm[0] = strings.toSlice("?client_id=");
        cm[1] = _client_id.toSlice();
        cm[2] = strings.toSlice("&client_secret=");
        cm[4] = _client_secret.toSlice();
        cred = strings.toSlice("").join(cm);        
    }
    
    function clearAPICredentials() only_owner {
         cred = "";
    }

    function getNextString(bytes _str, uint8 _pos) internal constant returns (string, uint8) {
        uint8 start = 0;
        uint8 end = 0;
        uint strl =_str.length;
        for (;strl > _pos; _pos++) {
            if (_str[_pos] == '"'){ //Found quotation mark
                if(_str[_pos-1] != '\\'){ //is not escaped
	                end = start == 0 ? 0: _pos;
	                start = start == 0 ? (_pos+1) : start;
	                if(end > 0) break; 
                }
            }
        }
    	bytes memory str = new bytes(end-start);
        for(_pos=0; _pos<str.length; _pos++){
            str[_pos] = _str[start+_pos];
        }
        for(_pos=end+1; _pos<_str.length; _pos++) if (_str[_pos] == ','){ _pos++; break; } //end

        return (string(str),_pos);
	}

    function getNextUInt(bytes _str, uint8 _pos) internal constant returns (uint, uint8) {
        uint val = 0;
        uint strl =_str.length;
        for (; strl > _pos; _pos++) {
            byte bp = _str[_pos];
            if (bp == ','){ //Find ends
                _pos++; break;
            }else if ((bp >= 48)&&(bp <= 57)){ //only ASCII numbers
                val *= 10;
                val += uint(bp) - 48;
            }
        }
        return (val,_pos);
    }

    function getNextAddr(bytes _str, uint8 _pos) internal constant returns (address, uint8){
        uint160 iaddr = 0;
        uint strl =_str.length;
        for(;strl > _pos; _pos++){
            byte bp = _str[_pos];
             if (bp == '0'){ 
                if (_str[_pos+1] == 'x'){
                    for (_pos=_pos+2; _pos<2+2*20; _pos+=2){
                        iaddr *= 256;
                        iaddr += (uint160(hexVal(uint160(_str[_pos])))*16+uint160(hexVal(uint160(_str[_pos+1]))));
                    }
                    _pos++; 
                    break;
                }
            }else if (bp == ','){ 
                _pos++; 
                break; 
            } 
        }
        return (address(iaddr),_pos);
    }
    
    function hexVal(uint val) internal constant returns (uint){
		return val - (val < 58 ? 48 : (val < 97 ? 55 : 87));
    }

}