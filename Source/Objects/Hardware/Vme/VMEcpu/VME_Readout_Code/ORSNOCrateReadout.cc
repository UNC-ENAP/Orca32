#include "ORSNOCrateReadout.hh"
#include "readout_code.h" 
#include <errno.h>
#include <iostream>


bool ORSNOCrateReadout::Start() {
	return true;
}

bool ORSNOCrateReadout::Stop() {
	return true;
	
}

bool ORSNOCrateReadout::Readout(SBC_LAM_Data* lamData)
{
	const uint32_t mem_read_reg = 0x270UL; //GetDeviceSpecificData()[0]; // 0x2CUL;
//	const uint32_t mem_write_reg = 0x274UL; //GetDeviceSpecificData()[1]; // 0x28UL;
	const uint32_t mem_diff_reg = 0x278UL; //GetDeviceSpecificData()[1]; // 0x28UL;
	const uint32_t data_avail_reg = 0x4UL;
	
	const uint32_t mem_base_address = 0x04800000UL; //GetDeviceSpecificData()[2]; // 0x03800000UL;
	const uint32_t mem_address_modifier = 0x09UL; //GetDeviceSpecificData()[3]; // 0x09UL;
//	uint32_t mem_write_ptr;
	
	uint32_t value = 0;
	uint32_t diff = 0;
	uint32_t read_ptr = 0;
	uint32_t data_avail = 0;
	
	//data available?
	if (VMERead(GetBaseAddress() + data_avail_reg, GetAddressModifier(),
		    sizeof(data_avail), data_avail) < (int32_t) sizeof(data_avail)){
		LogBusError("BusError: mem_access at: 0x%08x", GetBaseAddress() + data_avail_reg);
		return true; 
	}
	data_avail = data_avail & 0xffffUL ^ 0xffffUL;
		
	if (data_avail != 0) {
		//loop over the slots
		for (int i = 0; i < 16; i++) {
			if ((data_avail >> i) & 0x1UL) {
				value = 1 << i;
				if (VMEWrite(GetBaseAddress(), GetAddressModifier(), 
					     sizeof(value), value) < (int32_t) sizeof(value)) {
					LogBusError("BusError: deselect fec cards, %s\n", strerror(errno));
					return true; 
				}        		
				// get diff
				if (VMERead(GetBaseAddress() + mem_diff_reg, GetAddressModifier(),
					    sizeof(diff), diff) < (int32_t) sizeof(diff)){
					LogBusError("BusError: diff ptr at: 0x%08x", GetBaseAddress() + mem_diff_reg);
					return true; 
				}
				diff &= 0x000fffffUL;
				//get read ptr
				/*
				if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
					    sizeof(read_ptr), read_ptr) < (int32_t) sizeof(read_ptr)){
					LogBusError("BusError: read ptr at: 0x%08x", GetBaseAddress() + mem_read_reg);
					return true; 
				}
				*/
				if (diff > 2) {
					ensureDataCanHold(4);
					int32_t savedIndex = dataIndex;
					data[dataIndex++] = GetHardwareMask()[0] | 4;
					for (int j = 0; j < 3; j++) {
						if (VMERead(mem_base_address, mem_address_modifier,
							    sizeof(value), value) < (int32_t) sizeof(value)){
							LogBusError("BusError: pmt readout at: 0x%08x", mem_base_address);
							dataIndex = savedIndex;
							return true;
						}
						data[dataIndex++] = value;
					}
				}
				//get read
				/*
				if (VMERead(GetBaseAddress() + mem_read_reg, GetAddressModifier(),
					    sizeof(value), value) < (int32_t) sizeof(value)){
					LogBusError("BusError: diff ptr at: 0x%08x", GetBaseAddress() + mem_read_reg);
					return true; 
				}
				*/
				//too fast for the memory controller to inc
				//consistency check
				//store the readout memory ptr, if it is the same, do need read it out
				/*
				if (value > read_ptr && value - read_ptr != 3) {
					LogError("Error: consistency check failed.");										
				}
				else if () {
				}
				else
				*/	
			}
		}
		//deselect the card
		value = 0UL;
		if (VMEWrite(GetBaseAddress(), GetAddressModifier(), 
			     sizeof(value), value) < (int32_t) sizeof(value)) {
			LogBusError("BusError: deselect fec cards, %s\n", strerror(errno));
			return true; 
		}        		
	}
	
	return true; 
}

