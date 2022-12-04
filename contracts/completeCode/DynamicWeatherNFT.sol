// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts@4.8.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.8.0/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts@4.8.0/utils/Base64.sol";

interface WeatherInfo {
    function getCurrentConditions(bytes32 requestId_) external view returns (bytes memory);
    function requestId() external view returns (bytes32);
}

/// @title 天気情報で変化するNFT
/// @dev Custom Logicを使う
contract DynamicWeatherNFT is ERC721, ERC721URIStorage, Ownable, AutomationCompatible {
    /// @dev AutoWeatherInfoコントラクトへクエリするための変数
    WeatherInfo public weatherInfo;

    /// @dev Countersライブラリの全Functionを構造体Counter型に付与
    using Counters for Counters.Counter;

    // 付与したCounter型の変数_tokenIdCounterを定義
    Counters.Counter private _tokenIdCounter;

    // metaData更新回数のカウンター用変数を定義
    Counters.Counter private _updatedNFTCounter;

    /// @dev metaData更新回数の上限値
    uint public maxUpdateCount = 3;
    uint public curUpdateCount = _updatedNFTCounter.current();

    /// @dev NFTmint時のmetaFile初期設定
    string public startFile = "ipfs://bafkreihkc5vzdajtp4h6vafrzmld6spb2mbotscs6gjvanwowznyfbc6ly";

    /// @dev URI更新時に記録する
    event UpdateTokenURI(address indexed sender, uint256 indexed tokenId, string uri);

    // 前回の更新時間を記録する変数
    uint public lastTimeStamp;

    // 更新間隔を決める変数
    uint public interval;

    // AutoWeatherInfoから取得するrequestIdを保持するための状態変数
    bytes32 public latestRequestId;

    // 現在の天気情報を記録する構造体
    struct CurrentConditionsResult {
        uint256 timestamp;
        uint24 precipitationPast12Hours;
        uint24 precipitationPast24Hours;
        uint24 precipitationPastHour;
        uint24 pressure;
        int16 temperature;
        uint16 windDirectionDegrees;
        uint16 windSpeed;
        uint8 precipitationType;
        uint8 relativeHumidity;
        uint8 uvIndex;
        uint8 weatherIcon;
    }
    // Maps
    mapping(bytes32 => CurrentConditionsResult) public requestIdCurrentConditionsResult;

    constructor(uint interval_, address weatherInfo_) ERC721("DynamicWeatherNFT", "DWN") {
        interval = interval_;
        lastTimeStamp = block.timestamp;
        weatherInfo = WeatherInfo(weatherInfo_);
    }

    // checkUpkeep()に渡すcheckData(bytes型)を取得
    function getCheckData(uint tokenId_) public pure returns (bytes memory) {
        return abi.encode(tokenId_);
    }

    /// @dev metaData更新回数のカウンターリセット
    function resetUpdateCount() public {
        _updatedNFTCounter.reset();
        curUpdateCount = _updatedNFTCounter.current();
    }

    function getLatestRequestId() public view returns (bytes32) {
        return weatherInfo.requestId();
    }

    function getWeatherInfo(bytes32 requestId_) public view returns (CurrentConditionsResult memory) {
        bytes memory conditionEncoded = weatherInfo.getCurrentConditions(requestId_);
        CurrentConditionsResult memory condition = abi.decode(conditionEncoded, (CurrentConditionsResult));
        return condition;
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
            // AutoWeatherInfoから最新のrequestIdを取得して保持
            bytes32 weatherInfoRequestId = getLatestRequestId();
            // 以下条件を満たした場合にperformUpkeepを実行する
            // 1. 設定している更新間隔以上の時間が経過していること
            // 2. metaDataの更新回数が上限値以下であること
            // 3. AutoWeatherInfoから取得したrequestIdがlatestRequestIdと同じではないこと
            // 4. AutoWeatherInfoから取得した天気情報データが登録されていること(condition.timestamp)
            if (
                (block.timestamp - lastTimeStamp) >= interval
                &&
                curUpdateCount < maxUpdateCount
                &&
                latestRequestId != weatherInfoRequestId
            ) {
                bytes memory conditionEncoded = weatherInfo.getCurrentConditions(weatherInfoRequestId);
                CurrentConditionsResult memory condition = abi.decode(conditionEncoded, (CurrentConditionsResult));
                if (condition.timestamp != 0) {
                    // return値をセット
                    upkeepNeeded = true;
                    performData = abi.encode(targetId, weatherInfoRequestId, condition);
                } else {
                    // return値をセット
                    upkeepNeeded = false;
                    performData = '';
                }
            } else {
                // return値をセット
                upkeepNeeded = false;
                performData = '';
            }
        }

    // performDataにはtargetId, weatherInfoRequestId, conditionが入っている
    function performUpkeep(bytes calldata performData) external {
        (
            uint targetId, 
            bytes32 weatherInfoRequestId, 
            CurrentConditionsResult memory condition
        ) = abi.decode(performData, (uint, bytes32, CurrentConditionsResult));
        // tokenIdの存在チェック
        require(_exists(targetId), "non existent tokenId.");
        // checkUpkeepで行なった条件で再バリデーション
        if (
            (block.timestamp - lastTimeStamp) >= interval
            &&
            curUpdateCount < maxUpdateCount
            &&
            latestRequestId != weatherInfoRequestId
            &&
            condition.timestamp != 0
        ) {
            // 得られた天気情報を登録
            storeCurrentConditionsResult(weatherInfoRequestId, abi.encode(condition));
            // このコントラクトで管理しているlatestRequestIdを更新
            latestRequestId = weatherInfoRequestId;
            // lastTimeStampを現在のタイムスタンプに更新
            lastTimeStamp = block.timestamp;
            // NFTを更新
            _updateNFT(targetId, weatherInfoRequestId);
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
    }

    /// @dev tokenURIを変更し、Event発行
    function _updateNFT(uint _targetId, bytes32 _requestId) internal {
        // metadataを生成
        string memory uri = generateMetaData(_targetId, _requestId);
        // tokenURIを変更
        _setTokenURI(_targetId, uri);
        // NFTのupdate回数をincrement
        _updatedNFTCounter.increment();
        // NFTのupdate回数を更新
        curUpdateCount = _updatedNFTCounter.current();
        // Event発行
        emit UpdateTokenURI(msg.sender, _targetId, uri);
    }

    /// @dev metadataを生成する
    function generateMetaData(uint _targetId, bytes32 _requestId) public view returns (string memory) {
        CurrentConditionsResult memory condition = requestIdCurrentConditionsResult[_requestId];

        // struct CurrentConditionsResult {
        //     uint256 timestamp;
        //     uint24 precipitationPast12Hours;
        //     uint24 precipitationPast24Hours;
        //     uint24 precipitationPastHour;
        //     uint24 pressure;
        //     int16 temperature;
        //     uint16 windDirectionDegrees;
        //     uint16 windSpeed;
        //     uint8 precipitationType;
        //     uint8 relativeHumidity;
        //     uint8 uvIndex;
        //     uint8 weatherIcon;
        // }

        // 気温はint16型でマイナスがあり得るため、string型に型変換するための対応
        // uint系の型は、string型に型変換可能だが、int系の型は変換できないので工夫が必要
        string memory sTemp;
        // マイナスの気温だったら・・・
        if (condition.temperature < 0) {
            uint16 uTemp = uint16(-condition.temperature);
            // 文字列'-'を数字の前に追加する
            sTemp = string.concat('-', Strings.toString(uTemp));
        } else {
            // 0以上の気温だったらそのままstring型に型変換できる
            sTemp = Strings.toString(uint16(condition.temperature));
        }

        bytes memory metaData = abi.encodePacked(
            '{',
            '"name": "DynamicWeatherNFT # ',
            Strings.toString(_targetId),
            '",',
            '"description": "Dynamic Weather NFT!"',
            ',',
            '"image": "',
            getImageURI(condition.precipitationType),
            '",',
            '"attributes": [',
                '{',
                '"trait_type": "timestamp",',
                '"value": ',
                Strings.toString(condition.timestamp),
                '},'
                '{',
                '"trait_type": "pressure",',
                '"value": ',
                Strings.toString(condition.pressure),
                '},'
                '{',
                '"trait_type": "temperature",',
                '"value": ',
                sTemp,
                '},'
                '{',
                '"trait_type": "windSpeed",',
                '"value": ',
                Strings.toString(condition.windSpeed),
                '}'
            ']'
            '}'
        );
 
        string memory uri = string.concat("data:application/json;base64,",Base64.encode(metaData));
        return uri;
    }

    /// @dev imageURIの取得
    function getImageURI(uint8 precipitationType_) public pure returns (string memory) {
        string memory baseURI = "ipfs://bafybeiemg4yvdhl27lsctiae7yui5weu2jgvs3gmxr7w4v4yd6gqf7pq2q";
        return string.concat(baseURI, '/image', Strings.toString(precipitationType_), '.jpg');
    }

    /// @dev 天気情報を登録
    function storeCurrentConditionsResult(bytes32 _requestId, bytes memory _currentConditionsResult) private {
        CurrentConditionsResult memory result = abi.decode(_currentConditionsResult, (CurrentConditionsResult));
        requestIdCurrentConditionsResult[_requestId] = result;
    }

    /// @dev 以下は全てoverride 重複の整理
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

}