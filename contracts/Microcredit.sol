// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error DepositaInsuficiente();
error Deposito_Insuficiente();

error PrestamoActivo();
error Menosprestamo();
error PlazoIncorrecto();
error TasaIncorrecta();
error Loan_TransferFailed();
error IndiceOutTasas();

error NoPerteneceRemitente();
error YaPago();
error MontoPagadoInsuficiente();
error Pay_TransferFailed();

error NoDepositsFound();
error Withdraw_TransferFailed();

error toppeInvalid();
error TasaSeguroIncorrect();

error NoEsAseguradora();


contract Microcredit is Ownable {

    using PriceConverter for uint256;
    AggregatorV3Interface private s_priceFeed;


    AseguradoraInterface public aseguradoraContract;

    //1,700.000.000.000.000.000
    uint256 private s_maxLoan;
    uint256 private s_minDeposit;
    

    uint16[2] private s_interesRate;
    uint16[2] private s_interesTime;
    uint16 private s_tasaSeguro;

    uint256 private s_nextLoan = 1;

    // Estructura para representar un préstamo
    struct Loan {
        address prestador;
        address borrower;
        uint256 principal;
        uint16 interestRate; // Tasa de interés (porcentaje anual, por ejemplo, multiplicado por 100)
        uint256 startTime;
        uint256 deadline;
        uint256 amountToRepay; // Principal + intereses acumulados
    }

    struct Depost{
        uint256 avax;
        uint256 usd;
    }
    
    mapping(uint256 => Loan) private s_loans;
    mapping(address => Depost) private s_deposits;

    enum UserState{
        ACTIVO,
        INACTIVO,
        DESHABILITADO
    }
    mapping(address => UserState) public s_loans_States;
    mapping(address => uint256) private s_InterestGains;

    modifier onlyAseguradora(){
        if(msg.sender != address(aseguradoraContract)){
            revert NoEsAseguradora();
        }
        _;
    }


    event DepositIn(address indexed prestador, Depost valores);
    event LoanOut(uint256 indexed idBorrow, uint256 valor, uint256 deadline);
    event Pay_Loan(address indexed borrower);

    constructor(uint256 maxLoan, uint256 minDeposit, uint16 tasaInteresA, 
    uint16 tasaInteresB, uint16 plazoA, uint16 plazoB, address aseguradora, uint16 _tasaSeguro, address priceFeed) 
    Ownable(msg.sender) {
        s_maxLoan = maxLoan;
        s_minDeposit = minDeposit;
        s_interesRate[0] = tasaInteresA;
        s_interesRate[1] = tasaInteresB;
        s_interesTime[0] = plazoA;
        s_interesTime[1] = plazoB;
        aseguradoraContract = AseguradoraInterface(aseguradora);
        s_tasaSeguro = _tasaSeguro;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // Los usuarios envían AVAX directamente a esta función
    function deposit() external payable {
        if (msg.value < s_minDeposit) {
            revert DepositaInsuficiente();
        }
        s_deposits[msg.sender].avax += msg.value;
        s_deposits[msg.sender].usd += msg.value.getConversionRate(s_priceFeed);
        emit DepositIn(msg.sender, s_deposits[msg.sender]);
    }

    function borrow(uint256 _amount, address prestamista, uint8 classTasa) external {
        if (s_loans_States[msg.sender] == UserState.ACTIVO || s_loans_States[msg.sender] == UserState.DESHABILITADO) {
            revert PrestamoActivo();
        }
        if (_amount > s_maxLoan) {
            revert Menosprestamo();
        }
        if (_amount <= 0) {
            revert DepositaInsuficiente();
        }
        if (s_deposits[prestamista].avax <= _amount) {
            revert Deposito_Insuficiente();
        }
        if(classTasa != 0 && classTasa != 1){
            revert IndiceOutTasas();
        }

        uint256 interest = ((_amount * s_interesRate[classTasa]) / 100);
        uint256 repaymentAmount = _amount + interest;
        uint256 deadlineTimestamp = block.timestamp + (s_interesTime[classTasa] * 1 days);

        uint256 comisionWei = 22440000000000000; //0.02244 * 1e18

        uint256 repaymentAmountAA = repaymentAmount + comisionWei;

        s_loans_States[msg.sender] = UserState.ACTIVO;

        //*******************************Sacar 7% del saldo del prestamista para la poliza */
        uint256 montoAsegurado = (repaymentAmountAA * s_tasaSeguro) / 100;


        // Llama a la función asegurar del Contrato B y envía el 7% del valor
        aseguradoraContract.asegurar{value: montoAsegurado}(_amount, prestamista);

        //emit PagoRealizado(_montoTotal, montoAsegurado, msg.sender, address(contratoB));
        // event PagoRealizado(uint256 montoTotal, uint256 montoAsegurado, address pagador, address contratoB);

        // Transferir AVAX al prestatario
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Loan_TransferFailed();
        }
        s_loans[s_nextLoan] = Loan({
            prestador: prestamista,
            borrower: msg.sender,
            principal: _amount,
            interestRate: s_interesRate[classTasa],
            startTime: block.timestamp,
            deadline: deadlineTimestamp,
            amountToRepay: repaymentAmountAA
        });
        s_nextLoan += 1;
        s_deposits[prestamista].avax -= _amount; 
        uint256 usdValue = _amount.getConversionRate(s_priceFeed);
        if(s_deposits[prestamista].usd >= usdValue){
            s_deposits[prestamista].usd -= usdValue;
        }else{
            s_deposits[prestamista].usd = 0;
        }
        emit DepositIn(prestamista, s_deposits[prestamista]);

        emit LoanOut(s_nextLoan-1, repaymentAmountAA, deadlineTimestamp);
    }

    // Los prestatarios envían AVAX directamente a esta función para pagar
    function payLoan(uint256 _loanId) external payable {
        if (s_loans[_loanId].borrower != msg.sender) {
            revert NoPerteneceRemitente();
        }
        if (s_loans_States[msg.sender] == UserState.INACTIVO) {
            revert YaPago();
        }
        if (msg.value < s_loans[_loanId].amountToRepay) {
            revert MontoPagadoInsuficiente();
        }

        uint256 restante = msg.value - s_loans[_loanId].amountToRepay;

        if(s_loans_States[msg.sender] == UserState.ACTIVO){

            (bool success, ) = payable(s_loans[_loanId].prestador).call{value: s_loans[_loanId].amountToRepay}("");
            if (!success) {
                revert Pay_TransferFailed();
            }
            s_InterestGains[s_loans[_loanId].prestador] += s_loans[_loanId].interestRate;
        }
        
        s_loans_States[msg.sender] = UserState.INACTIVO;
        emit Pay_Loan(msg.sender);

        if(restante > 0){
            s_deposits[msg.sender].avax = restante;
            s_deposits[msg.sender].usd = restante.getConversionRate(s_priceFeed);
            emit DepositIn(msg.sender, s_deposits[msg.sender]);
        }
    
    }
    function withdraw() external {
        if(s_deposits[msg.sender].avax == 0){
            revert NoDepositsFound();
        }

        (bool success, ) = payable(msg.sender).call{value: s_deposits[msg.sender].avax}("");
        if(!success){
            revert Withdraw_TransferFailed();
        }
        s_deposits[msg.sender].avax = 0;
        s_deposits[msg.sender].usd = 0;
        emit DepositIn(msg.sender, s_deposits[msg.sender]);
    }

    //Interaccion Con la Aseguradora
    function ReportBorrower(uint256 indiceLoan) external onlyAseguradora{
        s_loans_States[s_loans[indiceLoan].borrower] = UserState.DESHABILITADO;
        s_InterestGains[s_loans[indiceLoan].prestador] += s_loans[indiceLoan].interestRate;
    }


    //onlyOwner - Modifiers
    function setMaxToLoan(uint256 _newToppe) external onlyOwner {
        if(_newToppe <= 0){
            revert toppeInvalid();
        }
        s_maxLoan = _newToppe;
    }
    function setMinDeposit(uint256 _newMinDep) external onlyOwner {
        if(_newMinDep <= 0){
            revert toppeInvalid();
        }
        s_minDeposit = _newMinDep;
    }
    function setTasaInteres(uint16 _newTasa, uint8 classTasa) external onlyOwner {
        if(classTasa != 0 && classTasa != 1){
            revert IndiceOutTasas();
        }
        s_interesRate[classTasa] = _newTasa;
    }
    function setInteresTime(uint16 _newTime, uint8 classTasa) external onlyOwner {
        if(classTasa != 0 && classTasa != 1){
            revert IndiceOutTasas();
        }
        s_interesTime[classTasa] = _newTime;
    }
    function setInteresTime(uint16 _newSeguro) external onlyOwner {
        if(_newSeguro <= 0){
            revert TasaSeguroIncorrect();
        }
        s_tasaSeguro = _newSeguro;
    }

    //gets
    function getMaxLoan() public view returns (uint256) {
        return s_maxLoan;
    }
    function getMinDeposit() public view returns (uint256) {
        return s_minDeposit;
    }
    function getTasaInteres(uint8 classTasa) public view returns (uint16) {
        return s_interesRate[classTasa];
    }
    function getInteresTime(uint8 classTasa) public view returns (uint16) {
        return s_interesTime[classTasa];
    }
    function getTasaSeguro() public view returns (uint16) {
        return s_tasaSeguro;
    }
    function getInfoPrestamista(address prestamista) public view returns (Depost memory, uint256) {
        return (s_deposits[prestamista], s_InterestGains[prestamista]);
    }
    function getInfoDeudor(uint256 idPrest) public view returns (Loan memory) {
        return s_loans[idPrest];
    }
    

   /*
    // Función para recuperar AVAX accidentalmente enviado al contrato
    function rescueAVAX(
        address payable _recipient,
        uint256 _amount
    ) external onlyOwner {
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transferencia de AVAX fallida.");
    }
    */
}


// Interfaz del Contrato Aseguradora
interface AseguradoraInterface {
    function asegurar(uint256 _mountTotal, address prestamista) external payable;
}


