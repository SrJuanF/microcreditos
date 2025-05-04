
# Hardhat Smartcontract MicroCredits - Assurance


## Pasos ##

Los wallets pueden depositan un saldo, convirtiendolos en prestamistas. Pueden retirar en cualquier momento su saldo disponibles (no prestado).

Las wallets puesen pedir prestado, convietiendolos en deudores. Solo adquieren un prestamo a la vaz, si tienen algun prestamo activo no les permite realizar mas prestamos. El manejon validaciones y errores en los procesos fueron escenciales.

La plataforma busca un prestamista con el saldo adecuado al prestamo solicitado. -- Atraves de la base de datos que escucha los eventos de la red blockchain para almacenarlos en tablas.

Los eventos emitidos desde la red blockchain a desplegar son: Cada transaccion de deposito, de prestamo, pago de prestamo y cada transaccion de retiro de saldo.

El momento en el que se encuentra un prestamista apto, se direcciona a la funcion borrow del smartcontract microCredit y que activa la poliza del prestamista que cubre su saldo prestado y sus ganancias futuras, enviando a la aseguradora el cobro de su tasa sobre el prestamo. Tambien se activa la tarifa por uso de la plataforma.

La aseguradora se considera otro modelo de negocion que tiene entre muchas otras funciones evaluar los perfies de usuarios, cubrir polizas... Por esto se creo otro smartcontract que interactua con los prestamistas de nuestra plataforma descentralizada de la siguiente manera:
Recibe los pagos del seguro de los prestamistas.

Utiliza una arquitectura descentralizada que  le permite recorrer una base de datos eficientemente para buscar cada cierto tiempo cual deudores no cancelaron su prestamo.

Interactuan con nuestro negocio para retribuir las polizas en caso de impago y de reportar como deshabilitados los usuarios en mora para evitar que pidan mas prestamos hasta que paguen el prestamo inicial al que incurrieron.






