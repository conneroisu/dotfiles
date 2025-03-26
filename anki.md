# Communication Protocol Flashcards

## Basic Protocol Properties

### Front: What duplex type does UART support?
### Back: Full duplex

### Front: What are the expandability options for I2C?
### Back: Large expandability

### Front: Does SPI support multi-master configuration?
### Back: No

### Front: What is the maximum speed of I2C High-speed mode?
### Back: 3.4 Mbps

### Front: What is the flow control characteristic of CAN?
### Back: No flow control (for single frame)

## Protocol Comparisons

### Front: Compare UART and SPI in terms of robustness.
### Back: UART has parity bit for error detection while SPI has no built-in robustness mechanisms.

### Front: Which protocol offers the highest speed among UART, I2C, SPI and CAN?
### Back: SPI (8+ Mbps)

### Front: Which protocols support multi-master configuration?
### Back: I2C and CAN

### Front: Compare I2C and CAN in terms of overhead components.
### Back: I2C: Start, 7-bit address, R/W bit, ACK/NACK
CAN: Start, 11-bit ID, 6-bit control, 16-bit CRC, 2-bit ACK, 7-bit EOF

### Front: Which protocol requires extra wires for additional slaves?
### Back: SPI (at cost of extra wire per slave)

## Protocol Details

### Front: What is included in UART protocol overhead?
### Back: Start bit, Stop bit, optional parity bit

### Front: What is the typical speed of UART?
### Back: ~100 Kbps

### Front: What are the three speed modes of I2C?
### Back: Standard: 100 Kbps
Fast: 400 Kbps
High-speed: 3.4 Mbps

### Front: What robustness features does CAN provide?
### Back: 16-bit CRC, ACK/NACK, Differential signaling

### Front: Which protocols support flow control?
### Back: Only I2C supports flow control

## Protocol Selection

### Front: Which protocol would be best for a simple point-to-point connection where speed is not critical?
### Back: UART (2-wire)

### Front: For a system requiring multiple devices with built-in error checking and moderate speed, which protocol is most suitable?
### Back: I2C

### Front: When maximum data transfer speed is the primary requirement, which protocol should be selected?
### Back: SPI (8+ Mbps)

### Front: For a robust automotive or industrial network with multiple masters, which protocol is most appropriate?
### Back: CAN

### Front: Which protocol uses the fewest wires for a point-to-point connection?
### Back: UART (2-wire)
