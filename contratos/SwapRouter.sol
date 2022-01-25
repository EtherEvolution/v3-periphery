// SPDX-License-Identifier: GPL-2.0-ou-posterior
solidez do pragma = 0 . 7 . 6 ;
pragma abicoder v2;

import  '@etherevolution/v3-core/contracts/libraries/SafeCast.sol' ;
import  '@etherevolution/v3-core/contracts/libraries/TickMath.sol' ;
import  '@etherevolution/v3-core/contracts/interfaces/IUniswapV3Pool.sol' ;

import  './interfaces/ISwapRouter.sol' ;
import  './base/PeripheryImmutableState.sol' ;
import  './base/PeripheryValidation.sol' ;
import  './base/PeripheryPaymentsWithFee.sol' ;
import  './base/Multicall.sol' ;
import  './base/SelfPermit.sol' ;
import  './libraries/Path.sol' ;
import  './libraries/PoolAddress.sol' ;
import  './libraries/CallbackValidation.sol' ;
import  './interfaces/external/IWETH9.sol' ;

/// @title Roteador Swap EtherEvolution V3
/// @notice Router para execução sem estado de swaps em relação ao EtherEvolution V3
contrato SwapRouter  é
    ISwapRouter,
    PeriferiaEstado Imutável,
    Validação de Periferia,
    PeriferiaPagamentosComTaxa,
    Multichamada,
    Autopermissão
{
    usando Caminho  para bytes;
    usando SafeCast  para uint256;

    /// @dev Usado como o valor de espaço reservado para amountInCached, porque o valor calculado para uma troca de saída exata
    /// nunca pode ser esse valor
constante privada      uint256 DEFAULT_AMOUNT_IN_CACHED = tipo ( uint256 ).max; 

    /// @dev Variável de armazenamento transitória usada para retornar o valor calculado para uma troca de saída exata.
    uint256  private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    construtor ( endereço  _factory , endereço  _WETH9 ) PeripheryImmutableState (_factory, _WETH9) {}

    /// @dev Retorna o pool para o par de tokens e a taxa fornecidos. O contrato de pool pode ou não existir.
    função getPool (
         token de endereçoA ,
         token de endereçoB ,
        taxa de uint24
    ) exibição privada  retorna (IEtherEvolutionV3Pool) { 
        return  IUniswapV3Pool (PoolAddress. computeAddress (fábrica, PoolAddress. getPoolKey (tokenA, tokenB, taxa)));
    }

    struct SwapCallbackData {
        caminho de bytes ;
        endereço do pagador;
    }

    /// @inheritdoc IEtherEvolutionV3SwapCallback
    função etherevolutionV3SwapCallback (
        int256  quantidade0Delta ,
        int256  quantidade1Delta ,
        bytes calldata _data
    ) substituição externa  {
        require (quantidade0Delta >  0  || quantidade1Delta >  0 ); // swaps inteiramente dentro de regiões de liquidez 0 não são suportados
Dados de memória         SwapCallbackData =  abi . decodificar (_data, (SwapCallbackData));
        ( endereço  tokenIn , endereço  tokenOut , uint24  fee ) = data.path. decodeFirstPool ();
        Validação de retorno de chamada. verifiqueCallback (fábrica, tokenIn, tokenOut, taxa);

        ( bool  isExactInput , uint256  amountToPay ) =
            quantidade0Delta >  0
                ? (tokenIn < tokenOut, uint256 (quantidade0Delta))
                : (tokenOut < tokenIn, uint256 (quantidade1Delta));
        if (isExactInput) {
            pay (tokenIn, data.payer, msg . sender , amountToPay);
        } senão {
            // inicia a próxima troca ou paga
            if (data.path. hasMultiplePools ()) {
                data.path = data.path. skipToken ();
                exactOutputInternal (amountToPay, msg . sender , 0 , data);
            } senão {
                valorInCached = valorParaPagar;
                tokenIn = tokenOut; // troca de entrada/saída porque as trocas de saída exatas são revertidas
                pay (tokenIn, data.payer, msg . sender , amountToPay);
            }
        }
    }

    /// @dev Executa uma única troca de entrada exata
    função exataInputInternal (
        uint256  valorIn ,
         destinatário do endereço ,
        uint160  sqrtPriceLimitX96 ,
Dados de memória         SwapCallbackData
    ) retornos privados  ( uint256 amountOut ) { 
        //permite trocar para o endereço do roteador com endereço 0
        if (destinatário ==  endereço ( 0 )) destinatário =  endereço ( this );

        ( endereço  tokenIn , endereço  tokenOut , uint24  fee ) = data.path. decodeFirstPool ();

        bool zeroForOne = tokenIn < tokenOut;

        ( int256  quantidade0 , int256  quantidade1 ) =
            getPool (tokenIn, tokenOut, taxa). trocar (
                destinatário,
                zeroForOne,
                Montante em. paraInt256 (),
                sqrtPriceLimitX96 ==  0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO +  1  : TickMath.MAX_SQRT_RATIO -  1 )
                    : sqrtPriceLimitX96,
                abi . codificar (dados)
            );

        return  uint256 ( - (zeroForOne ?  quantidade1 : quantidade0));
    }

    /// @inheritdoc ISwapRouter
    função exactInputSingle ( params de dados de chamada ExactInputSingleParams )
        externo
        a pagar
        sobrepor
        checkDeadline (params.deadline)
        retorna ( uint256  amountOut )
    {
quantidadeOut =          exactInputInternal (
            params.amountIn,
            params.destinatário,
            params.sqrtPriceLimitX96,
            SwapCallbackData ({ path : abi . encodePacked (params.tokenIn, params.fee, params.tokenOut), pagador : msg . sender })
        );
        require (amountOut >= params.amountOutMinimum, 'Recebido muito pouco' );
    }

    /// @inheritdoc ISwapRouter
    função exactInput (parâmetros de memória ExactInputParams )
        externo
        a pagar
        sobrepor
        checkDeadline (params.deadline)
        retorna ( uint256  amountOut )
    {
        endereço pagador = msg . remetente ; // msg.sender paga pelo primeiro salto

        enquanto ( verdadeiro ) {
            bool hasMultiplePools = params.path. temMúltiplosPools ();

            // as saídas de swaps anteriores se tornam as entradas para as subsequentes
            params.amountIn =  exactInputInternal (
                params.amountIn,
                temMúltiplas Piscinas ?  address ( this ) : params.recipient, // para swaps intermediários, este contrato guarda
                0 ,
                SwapCallbackData ({
                    caminho : params.path. getFirstPool (), // apenas o primeiro pool no caminho é necessário
                    pagador : pagador
                })
            );

            // decide se continua ou termina
            if (temMúltiplos Pools) {
                pagador =  endereço ( this ); // neste ponto, o chamador pagou
                params.path = params.path. skipToken ();
            } senão {
quantidadeOut =                 params.amountIn ;
                quebrar ;
            }
        }

        require (amountOut >= params.amountOutMinimum, 'Recebido muito pouco' );
    }

    /// @dev Executa uma única troca de saída exata
    função exactOutputInternal (
        uint256  valorOut ,
         destinatário do endereço ,
        uint160  sqrtPriceLimitX96 ,
Dados de memória         SwapCallbackData
    ) retornos privados  ( uint256 amountIn ) { 
        //permite trocar para o endereço do roteador com endereço 0
        if (destinatário ==  endereço ( 0 )) destinatário =  endereço ( this );

        ( endereço  tokenOut , endereço  tokenIn , uint24  fee ) = data.path. decodeFirstPool ();

        bool zeroForOne = tokenIn < tokenOut;

        ( int256  quantidade0Delta , int256  quantidade1Delta ) =
            getPool (tokenIn, tokenOut, taxa). trocar (
                destinatário,
                zeroForOne,
                - quantidadeSaída. paraInt256 (),
                sqrtPriceLimitX96 ==  0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO +  1  : TickMath.MAX_SQRT_RATIO -  1 )
                    : sqrtPriceLimitX96,
                abi . codificar (dados)
            );

        uint256 valorRecebido;
        (quantidadeEntrada, quantiaSaídaRecebida) = zeroForOne
            ? ( uint256 (quantidade0Delta), uint256 ( -quantidade1Delta ))
            : ( uint256 (quantidade1Delta), uint256 ( -quantidade0Delta ));
        // é tecnicamente possível não receber o valor total da saída,
        // então, se nenhum limite de preço foi especificado, exija essa possibilidade
        if (sqrtPriceLimitX96 ==  0 ) require (amountOutReceived == amountOut);
    }

    /// @inheritdoc ISwapRouter
    função exactOutputSingle ( params de dados de chamada ExactOutputSingleParams )
        externo
        a pagar
        sobrepor
        checkDeadline (params.deadline)
        retorna ( uint256  valorIn )
    {
        // evita um SLOAD usando os dados de retorno de troca
quantidadeIn =          exactOutputInternal (
            params.amountOut,
            params.destinatário,
            params.sqrtPriceLimitX96,
            SwapCallbackData ({ path : abi . encodePacked (params.tokenOut, params.fee, params.tokenIn), pagador : msg . sender })
        );

        require (amountIn <= params.amountInMaximum, 'Demasiado pedido' );
        // tem que ser redefinido mesmo que não o usemos no caso de salto único
        valorInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc ISwapRouter
    função exactOutput ( params de dados de chamada ExactOutputParams )
        externo
        a pagar
        sobrepor
        checkDeadline (params.deadline)
        retorna ( uint256  valorIn )
    {
        // tudo bem que o pagador seja fixado em msg.sender aqui, pois eles estão pagando apenas pela saída exata "final"
        // troca, que acontece primeiro, e as trocas subsequentes são pagas dentro de quadros de retorno de chamada aninhados
        exactOutputInternal (
            params.amountOut,
            params.destinatário,
            0 ,
            SwapCallbackData ({ path : params.path, payer : msg . sender })
        );

        quantidadeEm = quantidadeEmCache;
        require (amountIn <= params.amountInMaximum, 'Demasiado pedido' );
        valorInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}
