#ifndef _ORMTCReadout_hh_
#define _ORMTCReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>
#include <sys/time.h>

class ORMTCReadout : public ORVVmeCard
{
  public:
    ORMTCReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORMTCReadout() {} 
	virtual bool Start();
	virtual bool Readout(SBC_LAM_Data*);
	virtual bool Stop();
    bool UpdateStatus();
    bool ResetTheMemory();
	
protected:
	static uint32_t last_mem_read_ptr;
	static uint32_t mem_read_ptr;
    static uint32_t last_mem_write_ptr;
    static uint32_t mem_write_ptr;
    static uint32_t simm_empty_space;
    static float trigger_rate;
    static uint32_t last_good_gtid;
	
	const static uint32_t k_no_data_available = 0x00800000UL; //bit 23
	const static uint32_t k_fifo_valid_mask = 0x000fffffUL; //20 bits

    struct timeval timestamp;
    bool reset_the_memory;
    uint32_t last_good_10mhz_upper;
};

#endif /* _ORMTCReadout_hh_*/
