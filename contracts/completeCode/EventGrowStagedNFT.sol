// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts@4.8.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.8.0/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/// @title 時間で成長するNFT
/// @dev Custom Logicを使う
contract EventGrowStagedNFT is ERC721, ERC721URIStorage, Ownable, AutomationCompatible {
    /// @dev Countersライブラリの全Functionを構造体Counter型に付与
    using Counters for Counters.Counter;

    // 付与したCounter型の変数_tokenIdCounterを定義
    Counters.Counter private _tokenIdCounter;

    /// @dev stage設定
    enum Stages { Baby, Child, Youth, Adult, Grandpa }

    // mint時に設定する成長ステップを定数化
    Stages public constant firstStage = Stages.Baby;

    // tokenIdと現stageをマッピングする変数を定義
    mapping( uint => Stages ) public tokenStage;

    /// @dev NFTmint時は特定のURIを指定する
    string public startFile = "metadata1.json";

    /// @dev URI更新時に記録する
    event UpdateTokenURI(address indexed sender, uint256 indexed tokenId, string uri);

    // 前回の更新時間を記録する変数
    uint public lastTimeStamp;

    // 更新間隔を決める変数
    uint public interval;

    constructor(uint interval_) ERC721("EventGrowStagedNFT", "EGS") {
        interval = interval_;
        lastTimeStamp = block.timestamp;
    }

    // checkUpkeep()に渡すcheckData(bytes型)を取得
    function getCheckData(uint tokenId_) public pure returns (bytes memory) {
        return abi.encode(tokenId_);
    }

    // checkDataには、getCheckData()で得られたBytes型を指定
    function checkUpkeep(bytes calldata checkData) 
        external 
        view
        returns (bool upkeepNeeded, bytes memory performData) {
            // decodeして対象のtokenIdを取得
            uint targetId = abi.decode(checkData, (uint));
            // tokenIdの存在チェック
            require(_exists(targetId), "non existent tokenId.");
            // 次のStageを格納するuint型変数
            uint nextStage = uint(tokenStage[targetId]) + 1;
            if (
                (block.timestamp - lastTimeStamp) >= interval
                &&
                nextStage <= uint(type(Stages).max)
            ) {
                // return値をセット
                upkeepNeeded = true;
                performData = abi.encode(targetId, nextStage);
            } else {
                // return値をセット
                upkeepNeeded = false;
                performData = '';
            }
        }

    function performUpkeep(bytes calldata performData) external {
        (uint targetId, uint nextStage) = abi.decode(performData, (uint, uint));
        // tokenIdの存在チェック
        require(_exists(targetId), "non existent tokenId.");
        // 次のStageを格納するuint型変数
        uint vNextStage = uint(tokenStage[targetId]) + 1;
            if (
                (block.timestamp - lastTimeStamp) >= interval
                &&
                nextStage == vNextStage
                &&
                nextStage <= uint(type(Stages).max)
            ) {
                lastTimeStamp = block.timestamp;
                _growNFT(targetId, nextStage);
            }

    }

    /// @dev NFTをmint 初期stageとURIは固定
    function nftMint() public onlyOwner {
        // tokenIdを1増やす。tokenIdは1から始まる
        _tokenIdCounter.increment();
        // 現時点のtokenIdを取得
        uint256 tokenId = _tokenIdCounter.current();
        // NFTmint
        _safeMint(msg.sender, tokenId);
        // tokenURIを設定
        _setTokenURI(tokenId, startFile);
        // Event発行
        emit UpdateTokenURI(msg.sender, tokenId, startFile);
        // tokenId毎に成長ステップを記録
        tokenStage[tokenId] = firstStage;
    }

    /// @dev 成長できる余地があればtokenURIを変更しEventを発行する
    function _growNFT(uint targetId_, uint nextStage_) internal {
        // metaFileの決定
        string memory metaFile = string.concat("metadata",Strings.toString(nextStage_ + 1),".json");
        // tokenURIを変更
        _setTokenURI(targetId_, metaFile);
        // Stageの登録変更
        tokenStage[targetId_] = Stages(nextStage_);
        // Event発行
        emit UpdateTokenURI(msg.sender, targetId_, metaFile);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeichxrebqguwjqfyqurnwg5q7iarzi53p64gda74tgpg2uridnafva/";
    }

    /// @dev 以下は全てoverride 重複の整理
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

}