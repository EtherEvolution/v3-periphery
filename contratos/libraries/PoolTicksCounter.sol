// SPDX-License-Identifier: GPL-2.0-ou-posterior
solidez do pragma >= 0 . 6 . 0 ;

import  '@etherevolution/v3-core/contracts/interfaces/IEtherEvolutionV3Pool.sol' ;

biblioteca PoolTicksCounter {
    /// @dev Esta função conta o número de ticks inicializados que incorreriam em um custo de gás entre tickBefore e tickAfter.
    /// Quando tickBefore e/ou tickAfter são inicializados, a lógica sobre se devemos contá-los depende do
    /// direção da troca. Se estivermos trocando para cima (tickAfter > tickBefore), não queremos contar tickBefore, mas contamos
    /// deseja contar tickAfter. O oposto é verdadeiro se estivermos trocando para baixo.
    função countInitializedTicksCrossed (
        IEtherEvolutionV3Pool self,
        int24  tickAntes ,
        int24 tickDepois
    ) a visão interna  retorna ( uint32 initializedTicksCrossed ) {  
        int16 wordPosLower;
        int16 wordPosHigher;
        uint8 bitPosLower;
        uint8 bitPosHigher;
        bool tickBeforeInitialized;
        bool tickAfterInitialized;

        {
            // Obtém a chave e o deslocamento no bitmap de tick do tick ativo antes e depois da troca.
            int16 wordPos = int16 ((tickBefore / self. tickSpacing ()) >>  8 );
            uint8 bitPos = uint8 ((tickBefore / self. tickSpacing ()) %  256 );

            int16 wordPosAfter = int16 ((tickAfter / self. tickSpacing ()) >>  8 );
            uint8 bitPosAfter = uint8 ((tickAfter / self. tickSpacing ()) %  256 );

            // No caso em que tickAfter é inicializado, só queremos contá-lo se estivermos trocando para baixo.
            // Se o tick inicializável após a troca for inicializado, nosso tickAfter original é um
            // múltiplo do espaçamento de ticks, e estamos trocando para baixo, sabemos que tickAfter é inicializado
            // e não devemos contar.
            tickDepois de Inicializado =
                ((self. tickBitmap (wordPosAfter) & ( 1  << bitPosAfter)) >  0 ) &&
                ((tickAfter % self. tickSpacing ()) ==  0 ) &&
                (tickAntes > tickDepois);

            // No caso em que tickBefore é inicializado, só queremos contá-lo se estivermos trocando para cima.
            // Use a mesma lógica acima para decidir se devemos contar tickBefore ou não.
            tickBeforeInitialized =
                ((self. tickBitmap (wordPos) & ( 1  << bitPos)) >  0 ) &&
                ((tickBefore % self. tickSpacing ()) ==  0 ) &&
                (tickAntes < tickAfter);

            if (palavraPos < palavraPosDepois || (palavraPos == palavraPosDepois && bitPos <= bitPosDepois)) {
                palavraPosBaixo = palavraPos;
                bitPosBaixo = bitPos;
                palavraPosMaior = palavraPosDepois;
                bitPosMaior = bitPosDepois;
            } senão {
                wordPosLower = wordPosDepois;
                bitPosLower = bitPosDepois;
                palavraPosMaior = palavraPos;
                bitPosMaior = bitPos;
            }
        }

        // Conta o número de ticks inicializados cruzados pela iteração através do bitmap de tick.
        // Nossa primeira máscara deve incluir o tick inferior e tudo à sua esquerda.
        máscara uint256 = tipo ( uint256 ).max << bitPosLower;
        while (wordPosLower <= wordPosHigher) {
            // Se estivermos na página de bitmap de marcação final, certifique-se de que contamos apenas até o nosso
            // marca final.
            if (wordPosLower == wordPosHigher) {
                mascara = mascara & ( tipo ( uint256 ).max >> ( 255  - bitPosHigher));
            }

            uint256 mascarado = self. tickBitmap (wordPosLower) & mask;
            InitializedTicksCrossed +=  countOneBits (mascarado);
            wordPosLower ++ ;
            // Reinicia nossa máscara para que consideremos todos os bits na próxima iteração.
            máscara =  tipo ( uint256 ).max;
        }

        if (tickAfterInitialized) {
            inicializadoTicksCrossed -=  1 ;
        }

        if (tickBeforeInitialized) {
            inicializadoTicksCrossed -=  1 ;
        }

        return inicializadoTicksCrossed;
    }

    function countOneBits ( uint256  x ) private  pure  retorna ( uint16 ) {
        uint16 bits = 0 ;
        while (x !=  0 ) {
            bits ++ ;
            x &= (x -  1 );
        }
        bits de retorno ;
    }
}
