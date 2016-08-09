// Copyright (c) 2015, maldicion069 (Cristian Rodríguez) <ccrisrober@gmail.con>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.package com.example

struct KeyObject
{
	public:
		// Constructor
		this(int id, float x, float y, string color) {
			this.Id = id;
			this.setPosition(x, y);
			this.Color = color;
		}
		// Destructor
		~this() {

		}
		int getId() {
			return this.Id;
		}
		void setPosition(float x, float y) {
			this.PosX = x;
			this.PosY = y;
		}
		float getPosX() {
			return this.PosX;
		}
		float getPosY() {
			return this.PosY;
		}
		string getColor() {
			return this.Color;
		}
	protected:
		int Id;
		float PosX;
		float PosY;
		string Color;
}