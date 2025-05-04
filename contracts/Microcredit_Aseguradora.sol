// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
 
error NotCustomer();
error NotAmount();
error Seguro_TransferFailed();

contract Microcredit_Aseguradora is Ownable{

    microCreditsInterface private s_microCredits;
    mapping(address => uint256) private s_deposits;
    mapping(address => uint256) private s_poliza;


    event Aseguramiento(address indexed pagador, uint256 montoTotal, uint256 montoAsegurado);
    event Poliza(uint256 indexed deudor, address indexed prestamista, uint256 montoTotal);

    // Modifiers
    modifier onlyCustomer() {
        // require(msg.sender == i_owner);
        if (msg.sender != address(s_microCredits)) revert NotCustomer();
        _;
    }


    constructor() Ownable(msg.sender){}

    // Los usuarios envían el pago del seguro por cada transaccion
    function asegurar(uint256 _mountTotal, address prestamista) external payable onlyCustomer{
        s_deposits[prestamista] += msg.value;
        emit Aseguramiento(prestamista, _mountTotal, msg.value);
    }

    function CubrirSeguro(address _microCredits, address prestamista, uint256 indPrestamo, uint256 _amount) external onlyOwner{
        if(_microCredits != address(s_microCredits)){
            revert NotCustomer();
        }
        if(_amount <= 0){
            revert NotAmount();
        }
        (bool success, ) = payable(prestamista).call{value: _amount}("");
        if(!success){
            revert Seguro_TransferFailed();
        }
        s_poliza[address(s_microCredits)] += _amount;
        emit Poliza(indPrestamo, prestamista, _amount);

        s_microCredits.ReportBorrower(indPrestamo);

    }

    function setCustomer_Microcredits(address _microcredits) external onlyOwner {
        s_microCredits = microCreditsInterface(_microcredits);
    }
}

// Interfaz del Contrato A
interface microCreditsInterface {
    function ReportBorrower(uint256 indiceLoan) external;
}

