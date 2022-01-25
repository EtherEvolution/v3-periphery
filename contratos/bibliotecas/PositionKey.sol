// SPDX-License-Identifier: GPL-2.0-ou-posterior
solidez do pragma >= 0 . 5 . 0 ;

biblioteca PositionKey {
    /// @dev Retorna a chave da posição na biblioteca principal
    função calcular (
         proprietário do endereço ,
        int24  tickLower ,
        int24 tickUpper
    ) retornos puros internos  ( bytes32 ) { 
        return  keccak256 ( abi . encodePacked (proprietário, tickLower, tickUpper));
    }
}
