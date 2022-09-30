#include <Arduino.h>
#include <SoftwareSerial.h>

#define TX 2
#define RX 3

#define D5 4
#define D6 5
#define D7 6
#define M 7

SoftwareSerial desk(RX, TX);

/**
 * @brief Setup serial lines and pins for communication with computer and desk.
 */
void setup()
{
	// setup communication with desktop computer
	Serial.begin(9600);

	// setup communication with desk motor controller
	pinMode(TX, OUTPUT);
	pinMode(RX, INPUT);
	desk.begin(9600);

	pinMode(D5, OUTPUT);
	pinMode(D6, OUTPUT);
	pinMode(D7, OUTPUT);
	pinMode(M, OUTPUT);
}

/**
 * @brief Effectively release all simulated buttons.
 */
void reset()
{
	digitalWrite(D5, HIGH);
	digitalWrite(D6, HIGH);
	digitalWrite(D7, HIGH);
	digitalWrite(M, HIGH);
}

/**
 * @brief Forward packets between computer and desk, intercept button state packet to simulate user interaction.
 */
void loop()
{
	// forward display feedback
	while(desk.available())
	{
		Serial.write(desk.read());
	}

	if(Serial.peek() == 0xff)
	{
		// set button state, but wait for state bytes to have arrived
		if(Serial.available() >= 3)
		{
			Serial.read(); // = 0xff
			int buttons = Serial.read();
			// prevent errors due to one-bit-errors
			if(buttons == Serial.read())
			{
				bool m = buttons & 0x01;
				digitalWrite(D5, !m && buttons & 0x28 ? LOW : HIGH);
				digitalWrite(D6, !m && buttons & 0x14 ? LOW : HIGH);
				digitalWrite(D7, !m && buttons & 0x1a ? LOW : HIGH);
				digitalWrite(M, m ? LOW : HIGH);

				// automatically send keep-alive
				desk.write(0x11);
			}
		}
	}
	else if(Serial.available())
	{
		// fulfill originally available requests
		int request = Serial.read();
		if(request == 0x77)
		{
			reset();
		}

		if(request == 0x11 || request == 0x77)
		{
			desk.write(request);
		}
	}

	delay(25);
}
