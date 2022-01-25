// SPDX-License-Identifier: GPL-2.0-ou-posterior
solidez do pragma >= 0 . 6 . 8  < 0 . 8 . 0 ;

import  '@etherevolution/v3-core/contracts/interfaces/IEtherEvolutionV3Pool.sol' ;
import  '@etherevolution/v3-core/contracts/libraries/FixedPoint128.sol' ;
import  '@etherevolution/v3-core/contracts/libraries/TickMath.sol' ;
import  '@etherevolution/v3-core/contracts/libraries/Tick.sol' ;
import  '../interfaces/INonfungiblePositionManager.sol' ;
import  './LiquidityAmounts.sol' ;
import  './PoolAddress.sol' ;
import  './PositionKey.sol' ;

/// @title Retorna informações sobre o valor do token mantido em um NFT EtherEvolution V3
valor da posição da biblioteca {
    /// @notice Retorna os valores totais de token0 e token1, ou seja, a soma das taxas e principal
    /// que um determinado token de gerenciador de posição não fungível vale
    /// @param positionManager O EtherEvolution V3 NonfungiblePositionManager
    /// @param tokenId O tokenId do token para o qual obter o valor total
    /// @param sqrtRatioX96 O preço da raiz quadrada X96 para o qual calcular os valores principais
    /// @return amount0 O valor total do token0 incluindo principal e taxas
    /// @return amount1 O valor total do token1 incluindo principal e taxas
    função total (
        INonfungiblePositionManager positionManager,
        uint256  tokenId ,
        uint160 sqrtRatioX96
    ) exibição interna  retorna ( uint256 valor0 , uint256 valor1 ) {   
        ( uint256  valor0Principal , uint256  valor1Principal ) =  principal (positionManager, tokenId, sqrtRatioX96);
        ( uint256  valor0Fee , uint256  valor1Fee ) =  taxas (positionManager, tokenId);
        return (valor0Principal + valor0Taxa, valor1Principal + valor1Taxa);
    }

    /// @notice Calcula o principal (atualmente atuando como liquidez) devido ao proprietário do token no evento
    /// que a posição está queimada
    /// @param positionManager O EtherEvolution V3 NonfungiblePositionManager
    /// @param tokenId O tokenId do token para o qual obter o principal total devido
    /// @param sqrtRatioX96 O preço da raiz quadrada X96 para o qual calcular os valores principais
    /// @return amount0 O valor principal do token0
    /// @return amount1 O valor principal do token1
    função principal (
        INonfungiblePositionManager positionManager,
        uint256  tokenId ,
        uint160 sqrtRatioX96
    ) exibição interna  retorna ( uint256 valor0 , uint256 valor1 ) {   
        (, , , , , int24  tickLower , int24  tickUpper , uint128  liquidez , , , , ) = positionManager. posições (tokenId);

        Retorna
            Valores de Liquidez. getAmountsForLiquidity (
                sqrtRatioX96,
                TickMath. getSqrtRatioAtTick (tickLower),
                TickMath. getSqrtRatioAtTick (tickUpper),
                liquidez
            );
    }

    struct FeeParams {
        endereço token0;
        endereço token1;
        taxa uint24 ;
        int24 tickLower;
        int24 tickUpper;
        liquidez uint128 ;
        uint256 positionFeeGrowthInside0LastX128;
        uint256 positionFeeGrowthInside1LastX128;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
    }

    /// @notice Calcula as taxas totais devidas ao proprietário do token
    /// @param positionManager O EtherEvolution V3 NonfungiblePositionManager
    /// @param tokenId O tokenId do token para o qual obter as taxas totais devidas
    /// @return amount0 O valor das taxas devidas no token0
    /// @return amount1 O valor das taxas devidas no token1
    taxas de função (INonfungiblePositionManager positionManager, uint256  tokenId )
        interno
        visualizar
        retorna ( uint256  valor0 , uint256  valor1 )
    {
        (
            ,
            ,
            endereço  token0 ,
             token de endereço1 ,
             taxa uint24 ,
            int24  tickLower ,
            int24  tickUpper ,
             liquidez uint128 ,
            uint256  positionFeeGrowthInside0LastX128 ,
            uint256  positionFeeGrowthInside1LastX128 ,
            uint256  tokensOwed0 ,
            uint256 tokensOwed1
        ) = gerente de posição. posições (tokenId);

        Retorna
            _taxas (
                gerente de posição,
                FeeParams ({
                    token0 : token0,
                    token1 : token1,
                    taxa : taxa,
                    tickLower : tickLower,
                    tickUpper : tickUpper,
                    liquidez : liquidez,
                    positionFeeGrowthInside0LastX128 : positionFeeGrowthInside0LastX128,
                    positionFeeGrowthInside1LastX128 : positionFeeGrowthInside1LastX128,
                    tokensOwed0 : tokensOwed0,
                    tokensOwed1 : tokensOwed1
                })
            );
    }

    function _fees (INonfungiblePositionManager positionManager, FeeParams memory feeParams)
        privado
        visualizar
        retorna ( uint256  valor0 , uint256  valor1 )
    {
        ( uint256  poolFeeGrowthInside0LastX128 , uint256  poolFeeGrowthInside1LastX128 ) =
            _getFeeGrowthInside (
                IEtherEvolutionV3Pool (
                    Endereço da piscina. computarEndereço (
                        gerente de posição. fábrica (),
                        Endereço da piscina. PoolKey ({ token0 : feeParams.token0, token1 : feeParams.token1, fee : feeParams.fee})
                    )
                ),
                feeParams.tickLower,
                feeParams.tickUpper
            );

        quantidade0 =
            FullMath. mulDiv (
                poolFeeGrowthInside0LastX128 - feeParams.positionFeeGrowthInside0LastX128,
                taxaParams.liquidity,
                Ponto Fixo 128.Q128
            ) +
            taxaParams.tokensOwed0;

        quantidade1 =
            FullMath. mulDiv (
                poolFeeGrowthInside1LastX128 - feeParams.positionFeeGrowthInside1LastX128,
                taxaParams.liquidity,
                Ponto Fixo 128.Q128
            ) +
            taxaParams.tokensOwed1;
    }

    function _getFeeGrowthInside (
        IEtherEvolutionV3Pool pool,
        int24  tickLower ,
        int24 tickUpper
    ) retornos de exibição privada  ( uint256 feeGrowthInside0X128 , uint256 feeGrowthInside1X128 ) {   
        (, int24  tickCurrent , , , , , ) = pool. slot0 ();
        (, , uint256  lowerFeeGrowthOutside0X128 , uint256  lowerFeeGrowthOutside1X128 , , , , ) = pool. carrapatos (tickLower);
        (, , uint256  upperFeeGrowthOutside0X128 , uint256  upperFeeGrowthOutside1X128 , , , , ) = pool. carrapatos (tickUpper);

        if (tickCurrent < tickLower) {
            feeGrowthInside0X128 = lowerFeeGrowthOutside0X128 - upperFeeGrowthOutside0X128;
            feeGrowthInside1X128 = lowerFeeGrowthOutside1X128 - upperFeeGrowthOutside1X128;
        } else  if (tickCurrent < tickUpper) {
            uint256 feeGrowthGlobal0X128 = pool. feeGrowthGlobal0X128 ();
            uint256 feeGrowthGlobal1X128 = pool. feeGrowthGlobal1X128 ();
            feeGrowthInside0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128 - upperFeeGrowthOutside0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128 - upperFeeGrowthOutside1X128;
        } senão {
            feeGrowthInside0X128 = upperFeeGrowthOutside0X128 - lowerFeeGrowthOutside0X128;
            feeGrowthInside1X128 = upperFeeGrowthOutside1X128 - lowerFeeGrowthOutside1X128;
        }
    }
}
