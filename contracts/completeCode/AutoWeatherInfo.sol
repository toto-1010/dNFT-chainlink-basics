// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
/**
 * **** Data Conversions ****
 *
 * countryCode (bytes2)
 * --------------------
 * ISO 3166 alpha-2 codes encoded as bytes2
 * See: https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes
 *
 *
 * precipitationType (uint8)
 * --------------------------
 * Value    Type
 * --------------------------
 * 0        No precipitation
 * 1        Rain
 * 2        Snow
 * 3        Ice
 * 4        Mixed
 *
 *
 * weatherIcon (uint8)
 * -------------------
 * Each icon number is related with an image and a text
 * See: https://developer.accuweather.com/weather-icons
 *
 *
 * Decimals to integers (both metric & imperial units)
 * ---------------------------------------------------
 * Condition                    Conversion
 * ---------------------------------------------------
 * precipitationPast12Hours     multiplied by 100
 * precipitationPast24Hours     multiplied by 100
 * precipitationPastHour        multiplied by 100
 * pressure                     multiplied by 100
 * temperature                  multiplied by 10
 * windSpeed                    multiplied by 10
 *
 *
 * Current weather conditions units per system
 * ---------------------------------------------------
 * Condition                    metric      imperial
 * ---------------------------------------------------
 * precipitationPast12Hours     mm          in
 * precipitationPast24Hours     mm          in
 * precipitationPastHour        mm          in
 * pressure                     mb          inHg
 * temperature                  C           F
 * windSpeed                    km/h        mi/h
 *
 *
 * Other resources
 * ---------------
 * AccuWeather API docs:
 * http://apidev.accuweather.com/developers/
 *
 * Locations API Response Parameters:
 * http://apidev.accuweather.com/developers/locationAPIparameters#responseParameters
 *
 * Current Conditions API Response Parameters:
 * http://apidev.accuweather.com/developers/currentConditionsAPIParameters#responseParameters
 */
/**
 * @title A consumer contract for AccuWeather EA 'location-current-conditions' endpoint.
 * @author LinkPool.
 * @notice Request the current weather conditions for the given location coordinates (i.e. latitude and longitude).
 * @dev Uses @chainlink/contracts 0.4.0.
 */
contract AutoWeatherInfo is ChainlinkClient {
    // ChainlinkのStructのRequest型にアタッチ
    using Chainlink for Chainlink.Request;
    /* ========== CONSUMER STATE VARIABLES ========== */
    // リクエストパラメータを記録するための構造体
    struct RequestParams {
        uint256 locationKey;
        string endpoint;
        string lat;
        string lon;
        string units;
    }
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
    mapping(bytes32 => RequestParams) public requestIdRequestParams;

    // requestId
    bytes32 public requestId;

    /* ========== CONSTRUCTOR ========== */
    /**
     * @param _link the LINK token address.
     * @param _oracle the Operator.sol contract address.
     */
    // Polygon Mumbai Testnet
    // Constructorに渡すアドレス
    // _LINK(LINK Token Address): 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    // 以下、External Adapterの不具合が発生していたため、対応として独自構築したアドレスに変更
    // _ORACLE(Operator Address): 0x180ad6758CB9AEe034A298aE7a2C9EB77eC4ae84

     constructor(address _link, address _oracle) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
    }

    // コントラクト外への天気情報提供用ファンクション
    function getCurrentConditions(bytes32 requestId_) external view returns (bytes memory) {
        return abi.encode(requestIdCurrentConditionsResult[requestId_]);
    }

    /**
     * @notice Returns the current weather conditions of a location by ID.
     * @param _specId the jobID.
     * @param _payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     * @param _locationKey the location ID.
     * @param _units the measurement system ("metric" or "imperial").
     */
    // requestCurrentConditionsファンクションに渡すパラメータ
    // _specId( JobIDs as Bytes32):current-conditions ->  0x3065663665363038383065323463623639636239396131636164373666313561
    // _payment(0.1LINK => 10^17 Juels): 100000000000000000
    // _locationKey(日本を示すlocationID) : 226396
    //  _units: metric   
    function requestCurrentConditions(
        bytes32 _specId,
        uint256 _payment,
        uint256 _locationKey,
        string calldata _units
    ) public {
        // リクエストの生成
        Chainlink.Request memory req = buildChainlinkRequest(
            _specId,
            address(this),
            this.fulfillCurrentConditions.selector
        );
        // Job指定ができれば不要
        // req.add("endpoint", "current-conditions"); // NB: not required if it has been hardcoded in the job spec
        req.addUint("locationKey", _locationKey);
        req.add("units", _units);
        // リクエストを実施しrequestIdを得る
        requestId = sendChainlinkRequest(req, _payment);
        // requestIdに紐づけて結果を記録        
        // Below this line is just an example of usage
        storeRequestParams(requestId, _locationKey, "current-conditions", "0", "0", _units);
    }

    /**
     * @notice Consumes the data returned by the node job on a particular request.
     * @param _requestId the request ID for fulfillment.
     * @param _currentConditionsResult the current weather conditions (encoded as CurrentConditionsResult).
     */
    function fulfillCurrentConditions(bytes32 _requestId, bytes memory _currentConditionsResult)
        public
        // コールバックが悪意のある呼び出し元から呼び出されないように保護する
        recordChainlinkFulfillment(_requestId)
    {
        // requestIdに紐づけて結果を記録        
        storeCurrentConditionsResult(_requestId, _currentConditionsResult);
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    function storeRequestParams(
        bytes32 _requestId,
        uint256 _locationKey,
        string memory _endpoint,
        string memory _lat,
        string memory _lon,
        string memory _units
    ) private {
        RequestParams memory requestParams;
        requestParams.locationKey = _locationKey;
        requestParams.endpoint = _endpoint;
        requestParams.lat = _lat;
        requestParams.lon = _lon;
        requestParams.units = _units;
        requestIdRequestParams[_requestId] = requestParams;
    }
    function storeCurrentConditionsResult(bytes32 _requestId, bytes memory _currentConditionsResult) private {
        CurrentConditionsResult memory result = abi.decode(_currentConditionsResult, (CurrentConditionsResult));
        requestIdCurrentConditionsResult[_requestId] = result;
    }

    /* ========== OTHER FUNCTIONS ========== */
    // 登録したOracleContractアドレスを戻す
    function getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }
    // OracleContractアドレスを設定する
    function setOracle(address _oracle) external {
        setChainlinkOracle(_oracle);
    }
    // 預けているLINKトークンを引き出す
    function withdrawLink() public {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }

}
