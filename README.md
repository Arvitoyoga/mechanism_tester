# Mechanism Tester

Mechanism Tester is a desktop application developed to monitor, test, and control multiple robotic and UAV mechanisms from a single interface.

The application serves as a testing platform during development, allowing operators to verify actuator functionality, monitor system status, and manually control connected mechanisms before deployment.

---

## Features

- Real-time mechanism monitoring
- Manual actuator control
- Servo testing interface
- Sequential dropping mechanism control
- System status monitoring
- Easy-to-use graphical interface
- Designed for rapid debugging and development

---

## Supported Mechanisms

The application can be used to test and monitor:

- Servo-based dropping mechanisms
- Payload release systems
- Robotic actuators
- UAV deployment mechanisms
- Custom embedded systems

---

## System Architecture

```text
+-------------------+
|  Mechanism Tester |
|     Desktop App   |
+---------+---------+
          |
          | Serial Communication
          |
+---------v---------+
|   Microcontroller |
| (ESP32 / Arduino) |
+---------+---------+
          |
          |
  +-------+-------+
  |               |
Servos       Sensors
