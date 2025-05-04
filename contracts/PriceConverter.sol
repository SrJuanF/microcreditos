// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    // Retorna el precio de AVAX en USD con 18 decimales (ajustado desde 8)
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            , 
            int256 answer, 
            , 
            , 
        ) = priceFeed.latestRoundData();

        // AVAX/USD típicamente tiene 8 decimales en Chainlink
        // Para escalarlo a 18 decimales, multiplicamos por 10^10
        uint8 decimals = priceFeed.decimals();
        uint256 scalingFactor = 10**(uint256(18) - decimals);

        return uint256(answer) * scalingFactor;
    }

    // Convierte un monto en AVAX a USD, usando el precio escalado a 18 decimales
    function getConversionRate(
        uint256 avaxAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 avaxPrice = getPrice(priceFeed);
        uint256 avaxAmountInUsd = (avaxPrice * avaxAmount) / 1e18;
        return avaxAmountInUsd;
    }
}
