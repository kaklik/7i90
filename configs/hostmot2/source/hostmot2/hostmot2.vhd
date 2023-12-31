library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;
--
-- Copyright (C) 2007, Peter C. Wallace, Mesa Electronics
-- http://www.mesanet.com
--
-- This program is is licensed under a disjunctive dual license giving you
-- the choice of one of the two following sets of free software/open source
-- licensing terms:
--
--    * GNU General Public License (GPL), version 2.0 or later
--    * 3-clause BSD License
-- 
--
-- The GNU GPL License:
-- 
--     This program is free software; you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation; either version 2 of the License, or
--     (at your option) any later version.
-- 
--     This program is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
-- 
--     You should have received a copy of the GNU General Public License
--     along with this program; if not, write to the Free Software
--     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
-- 
-- 
-- The 3-clause BSD License:
-- 
--     Redistribution and use in source and binary forms, with or without
--     modification, are permitted provided that the following conditions
--     are met:
-- 
--         * Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
-- 
--         * Redistributions in binary form must reproduce the above
--           copyright notice, this list of conditions and the following
--           disclaimer in the documentation and/or other materials
--           provided with the distribution.
-- 
--         * Neither the name of Mesa Electronics nor the names of its
--           contributors may be used to endorse or promote products
--           derived from this software without specific prior written
--           permission.
-- 
-- 
-- Disclaimer:
-- 
--     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
--     COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
--     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
--     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
--     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
--     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
--     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
--     POSSIBILITY OF SUCH DAMAGE.
-- 

use work.IDROMConst.all;	
library UNISIM;
use UNISIM.VComponents.all;
use work.log2.all;
use work.decodedstrobe.all;	
use work.oneofndecode.all;	
use work.IDROMConst.all;	
use work.NumberOfModules.all;	
use work.MaxPinsPerModule.all;	
use work.MaxInputPinsPerModule.all;	
use work.InputPinsPerModule.all;	
use work.MaxOutputPinsPerModule.all;	
use work.MaxIOPinsPerModule.all;	
use work.CountPinsInRange.all;
use work.PinExists.all;	
use work.ModuleExists.all;	
	
entity HostMot2 is
  	generic
	(  
		ThePinDesc: PinDescType;
		TheModuleID: ModuleIDType;
		IDROMType: integer;		
	   SepClocks: boolean;
		OneWS: boolean;
		UseIRQLogic: boolean;
		PWMRefWidth  : integer;
		UseWatchDog: boolean;
		OffsetToModules: integer;
		OffsetToPinDesc: integer;
		ClockHigh: integer;
		ClockMed: integer;
		ClockLow: integer;
		BoardNameLow : std_Logic_Vector(31 downto 0);
		BoardNameHigh : std_Logic_Vector(31 downto 0);
		FPGASize: integer;
		FPGAPins: integer;
		IOPorts: integer;
		IOWidth: integer;
		LIOWidth: integer;
		PortWidth: integer;
		BusWidth: integer;
		AddrWidth: integer;
		InstStride0: integer;
		InstStride1: integer;
		RegStride0: integer;
		RegStride1: integer;
		LEDCount: integer
		);
	port 
   (
     -- Generic 32  bit bus interface signals --

	ibus: in std_logic_vector(buswidth -1 downto 0);
	obus: out std_logic_vector(buswidth -1 downto 0);
	addr: in std_logic_vector(addrwidth -1 downto 2);
	readstb: in std_logic;
	writestb: in std_logic;
	clklow: in std_logic;
	clkmed: in std_logic;
	clkhigh: in std_logic;
	int: out std_logic; 
	dreq: out std_logic;
	demandmode: out std_logic;
	iobits: inout std_logic_vector (iowidth -1 downto 0);			
	liobits: inout std_logic_vector (liowidth -1 downto 0);
	rates: out std_logic_vector (4 downto 0);
	leds: out std_logic_vector(ledcount-1 downto 0)
	);
end HostMot2;



architecture dataflow of HostMot2 is


-- decodes --
--	IDROM related signals
	-- Extract the number of modules of each type from the ModuleID
constant StepGens: integer := NumberOfModules(TheModuleID,StepGenTag);
constant QCounters: integer := NumberOfModules(TheModuleID,QCountTag);
constant MuxedQCounters: integer := NumberOfModules(TheModuleID,MuxedQCountTag);			-- non-muxed index mask
constant MuxedQCountersMIM: integer := NumberOfModules(TheModuleID,MuxedQCountMIMTag); -- muxed index mask
constant PWMGens : integer := NumberOfModules(TheModuleID,PWMTag);
constant UsePWMEnas: boolean := PinExists(ThePinDesc,PWMTag,PWMCEnaPin);
constant TPPWMGens : integer := NumberOfModules(TheModuleID,TPPWMTag);
constant SPIs: integer := NumberOfModules(TheModuleID,SPITag);
constant BSPIs: integer := NumberOfModules(TheModuleID,BSPITag);
constant DBSPIs: integer := NumberOfModules(TheModuleID,DBSPITag);
constant SSSIs: integer := NumberOfModules(TheModuleID,SSSITag);   
constant FAbss: integer := NumberOfModules(TheModuleID,FAbsTag); 
constant BISSs: integer := NumberOfModules(TheModuleID,BISSTag);   
constant UARTs: integer := NumberOfModules(TheModuleID,UARTRTag); -- assumption 

constant PktUARTs: integer := NumberOfModules(TheModuleID,PktUARTRTag); -- assumption 
constant WaveGens: integer := NumberOfModules(TheModuleID,WaveGenTag);
constant ResolverMods: integer := NumberOfModules(TheModuleID,ResModTag);
constant SSerials: integer := NumberOfModules(TheModuleID,SSerialTag);
type  SSerialType is array(0 to 3) of integer;
constant UARTSPerSSerial: SSerialType :=( 
(InputPinsPerModule(ThePinDesc,SSerialTag,0)),
(InputPinsPerModule(ThePinDesc,SSerialTag,1)),
(InputPinsPerModule(ThePinDesc,SSerialTag,2)),
(InputPinsPerModule(ThePinDesc,SSerialTag,3)));
constant MaxUARTSPerSSerial: integer := MaxInputPinsPerModule(ThePinDesc,SSerialTag);
constant	Twiddlers: integer := NumberOfModules(TheModuleID,TwiddlerTag);
constant InputsPerTwiddler: integer := MaxInputPinsPerModule(ThePinDesc,TwiddlerTag)+MaxIOPinsPerModule(ThePinDesc,TwiddlerTag);
constant OutputsPerTwiddler: integer := MaxOutputPinsPerModule(ThePinDesc,TwiddlerTag); -- MaxOutputsPer pin counts I/O pins also
constant RegsPerTwiddler: integer := 4;	-- until I find a per instance way of doing this	
constant DAQFIFOs: integer := NumberOfModules(TheModuleID,DAQFIFOTag);
constant DAQFIFOWidth: integer := MaxInputPinsPerModule(ThePinDesc,DAQFIFOTag); -- until I find a per instance way of doing this
constant	UseDemandModeDMA: boolean := ModuleExists(TheModuleID,DMDMATag);		-- demand mode DMA must be explicitly included in the module ID
constant NDRQs: integer := NumberOfModules(TheModuleID,DAQFIFOTag); -- + any other drq sources that are used
constant BinOscs: integer := NumberOfModules(TheModuleID,BinOscTag);
constant BinOscWidth: integer := MaxOutputPinsPerModule(ThePinDesc,BinOscTag);
constant HM2DPLLs: integer := NumberOfModules(TheModuleID,HM2DPLLTag);
constant ScalerCounters: integer := NumberOfModules(TheModuleID,ScalerCounterTag);

-- extract the needed Stepgen table width from the max pin# used with a stepgen tag
constant StepGenTableWidth: integer := MaxPinsPerModule(ThePinDesc,StepGenTag);
	-- extract how many BSPI CS pins are needed
constant BSPICSWidth: integer := CountPinsInRange(ThePinDesc,BSPITag,BSPICS0Pin,BSPICS7Pin);
	-- extract how many DBSPI CS pins are needed
constant DBSPICSWidth: integer := CountPinsInRange(ThePinDesc,DBSPITag,DBSPICS0Pin,DBSPICS7Pin);

constant UseProbe: boolean := PinExists(ThePinDesc,QCountTag,QCountProbePin);
constant UseMuxedProbe: boolean := PinExists(ThePinDesc,MuxedQCountTag,MuxedQCountProbePin);
constant UseStepgenIndex: boolean := PinExists(ThePinDesc,StepGenTag,StepGenIndexPin);
constant UseStepgenProbe: boolean := PinExists(ThePinDesc,StepGenTag,StepGenProbePin);

-- all these signals should be put in per module components
-- to reduce clutter

	signal A: std_logic_vector(addrwidth -1 downto 2);
	signal LoadIDROM: std_logic;
	signal ReadIDROM: std_logic;

	signal LoadIDROMWEn: std_logic;
	signal ReadIDROMWEn: std_logic;

	signal IDROMWEn: std_logic_vector(0 downto 0);
	signal ROMAdd: std_logic_vector(7 downto 0);

-- I/O port related signals

	signal AltData :  std_logic_vector(IOWidth-1 downto 0) := (others => '0'); 
	signal PortSel: std_logic;	
	signal LoadPortCmd: std_logic_vector(IOPorts -1 downto 0);
	signal ReadPortCmd: std_logic_vector(IOPorts -1 downto 0);

	signal DDRSel: std_logic;	
	signal LoadDDRCmd: std_logic_vector(IOPorts -1 downto 0);
	signal ReadDDRCmd: std_logic_vector(IOPorts -1 downto 0);	
	signal AltDataSrcSel: std_logic;
	signal LoadAltDataSrcCmd: std_logic_vector(IOPorts -1 downto 0);
	signal OpenDrainModeSel: std_logic;
	signal LoadOpenDrainModeCmd: std_logic_vector(IOPorts -1 downto 0);
	signal OutputInvSel: std_logic;
	signal LoadOutputInvCmd: std_logic_vector(IOPorts -1 downto 0);

-- qcounter related signals
	signal Probe : std_logic; -- hs probe input for counters,stepgens etc

-- PWM related signals (this is global because its shared by two modules)
	signal RefCountBus : std_logic_vector(PWMRefWidth-1 downto 0);

--- Watchdog related signals 
	signal LoadWDTime : std_logic; 
	signal ReadWDTime : std_logic;
	signal LoadWDStatus : std_logic;
	signal ReadWDStatus : std_logic;
	signal WDCookie: std_logic;
	signal WDBite : std_logic;
	signal WDLatchedBite : std_logic;

--- Demand mode DMA related signals
	signal LoadDMDMAMode: std_logic;
	signal ReadDMDMAMode: std_logic;
	signal DRQSources: std_logic_vector(NDRQs -1 downto 0);

--- ID related signals
	signal ReadID : std_logic;

--- LED related signals
	signal LoadLEDS : std_logic;

-- Timer related signals	
	signal DPLLTimers: std_logic_vector(3 downto 0);
	signal DPLLRefOut: std_logic;
	signal RateSources: std_logic_vector(4 downto 0);
	
	function bitreverse(v: in std_logic_vector) -- Thanks: J. Bromley
	return std_logic_vector is
	variable result: std_logic_vector(v'RANGE);
	alias tv: std_logic_vector(v'REVERSE_RANGE) is v;
	begin
		for i in tv'RANGE loop
			result(i) := tv(i);
		end loop;
		return result;
	end;

	
	begin
	ahosmotid : entity work.hostmotid
		generic map ( 
			buswidth => BusWidth,
			cookie => Cookie,
			namelow => HostMotNameLow ,
			namehigh => HostMotNameHigh,
			idromoffset => IDROMOffset
			)			
		port map ( 
			readid => ReadID,
			addr => A(3 downto 2),
			obus => obus
			);


	makeoports: for i in 0 to IOPorts -1 generate
		oportx: entity work.WordPR 
		generic map (
			size => PortWidth,
			buswidth => BusWidth
			)		
		port map (
			clear => WDBite,
			clk => clklow,
			ibus => ibus,
			obus => obus,
			loadport => LoadPortCmd(i),
			loadddr => LoadDDRCmd(i),
			loadaltdatasrc => LoadAltDataSrcCmd(i),
			loadopendrainmode => LoadOpenDrainModeCmd(i),
			loadinvert => LoadOutputInvCmd(i),
			readddr => ReadDDRCmd(i),
			portdata => IOBits((((i+1)*PortWidth) -1) downto (i*PortWidth)), 
			altdata => Altdata((((i+1)*PortWidth) -1) downto (i*PortWidth))
			);	
	end generate;

	makeiports: for i in 0 to IOPorts -1 generate
		iportx: entity work.WordRB 		  
		generic map (size => PortWidth,
						 buswidth => BusWidth)
		port map (
		obus => obus,
		readport => ReadPortCmd(i),
		portdata => IOBits((((i+1)*PortWidth) -1) downto (i*PortWidth))
 		);	
	end generate;

	makewatchdog: if UseWatchDog generate  
		wdogabittus: entity work.watchdog
		generic map ( buswidth => BusWidth)
		
		port map (
			clk => clklow,
			ibus => ibus,
			obus => obus,
			loadtime => LoadWDTime, 
			readtime => ReadWDTime,
			loadstatus=> LoadWDStatus,
			readstatus=> ReadWDStatus,
			cookie => WDCookie,
			wdbite => WDBite,
			wdlatchedbite => WDLatchedBite
			);
		end generate;

	makedrqlogic: if UseDemandModeDMA generate
		somolddrqlogic: entity work.dmdrqlogic
		generic map( ndrqs => NDRQs )
		port map(
			clk => clklow,
			ibus => ibus,
			obus => obus,
			loadmode => LoadDMDMAMode,
			readmode => ReadDMDMAMode,
			drqsources => DRQSources,
			dreqout => dreq,					-- passed directly to top
			demandmode => demandmode		-- passed directly to top
			);
		end generate;	

	makenodrqlogic: if not UseDemandModeDMA generate
		dreq <= '0';							-- passed directly to top
		demandmode <= '0';					-- passed directly to top
	end generate;	
			
	makeirqlogic: if UseIRQlogic generate
	signal LoadIRQStatus : std_logic;
	signal ReadIrqStatus : std_logic;
	signal ClearIRQ : std_logic;	
	begin
	somoldirqlogic: entity work.irqlogics    
		generic map( 
			buswidth =>  BusWidth
				)	
		port map ( 
			clk => clklow,
			ibus => ibus,
         obus =>  obus,
         loadstatus => LoadIRqStatus,
         readstatus => ReadIRqStatus,
         clear =>  ClearIRQ,
         ratesource => RateSources, -- DPLL timer channels, channel 4 is refout
         int => INT);
			
		IRQDecodePRocess: process(A,readstb,writestb)
		begin	
			if A(15 downto 8) = IRQStatusAddr and writestb = '1' then	 --  
				LoadIRQStatus <= '1';
			else
				LoadIRQStatus <= '0';
			end if;
			if A(15 downto 8) = IRQStatusAddr and readstb = '1' then	 --  
				ReadIrqStatus <= '1';
			else
				ReadIrqStatus <= '0';
			end if;
			if A(15 downto 8) = ClearIRQAddr and writestb = '1' then	 --  
				ClearIRQ <= '1';
			else
				ClearIRQ <= '0';
			end if;
		end process;
	
	end generate;

	makehm2dpllmod:  if HM2DPLLs >0  generate	
	signal LoadDPLLBaseRate: std_logic;
	signal ReadDPLLBaseRate: std_logic;     
	signal LoadDPLLPhase: std_logic;     
	signal ReadDPLLPhase: std_logic;
	signal LoadDPLLControl0: std_logic;
	signal ReadDPLLControl0: std_logic;
	signal LoadDPLLControl1: std_logic;
	signal ReadDPLLControl1: std_logic;
	signal LoadDPLLTimers12: std_logic;
	signal ReadDPLLTimers12: std_logic;
	signal LoadDPLLTimers34: std_logic;
	signal ReadDPLLTimers34: std_logic;
	signal ReadSyncDPLL: std_logic;
	signal WriteSyncDPLL: std_logic;
	signal DPLLSyncIn: std_logic;
	
	begin
		hm2dpll: entity work.HM2DPLL
		port  map ( 
			clk => clklow,    		
			ibus => ibus,   		
			obus => obus,  		
			loadbaserate => LoadDPLLBaseRate,
			readbaserate => ReadDPLLBaseRate,
			loadphase => LoadDPLLPhase,	  
			readphase => ReadDPLLPhase,  
			loadcontrol0 => LoadDPLLControl0,
			readcontrol0 => ReadDPLLControl0,
			loadcontrol1 => LoadDPLLControl1,
			readcontrol1 => ReadDPLLControl1,
			loadtimers12 => LoadDPLLTimers12,
			readtimers12 => ReadDPLLTimers12,
			loadtimers34 => LoadDPLLTimers34,
			readtimers34 => ReadDPLLTimers34,
			syncwrite => WriteSyncDPLL,	
			syncread	=> ReadSyncDPLL,
			syncin => DPLLSyncIn,	
			timerout => DPLLTimers,
			refout	=> DPLLRefOut	
			);

		HM2DPLLDecodeProcess : process (A,Readstb,writestb,DPLLTimers,RateSources,DPLLRefOut)
		begin		
			if A(15 downto 8) = HM2DPLLBaseRateAddr and writestb = '1' then	 --  
				LoadDPLLBaseRate <= '1';
			else
				LoadDPLLBaseRate <= '0';
			end if;
			if A(15 downto 8) = HM2DPLLBaseRateAddr and readstb = '1' then	 --  
				ReadDPLLBaseRate <= '1';
			else
				ReadDPLLBaseRate <= '0';
			end if;

			if A(15 downto 8) = HM2PhaseErrAddr and writestb = '1' then	 --  
				LoadDPLLPhase <= '1';
			else
				LoadDPLLPhase <= '0';
			end if;
			if A(15 downto 8) = HM2PhaseErrAddr and readstb = '1' then	 --  
				ReadDPLLPhase <= '1';
			else
				ReadDPLLPhase <= '0';
			end if;
	
			if A(15 downto 8) = HM2DPLLControl0Addr and writestb = '1' then	 --  
				LoadDPLLControl0 <= '1';
			else
				LoadDPLLControl0 <= '0';
			end if;
			if A(15 downto 8) = HM2DPLLControl0Addr and readstb = '1' then	 --  
				ReadDPLLControl0 <= '1';
			else
				ReadDPLLControl0 <= '0';
			end if;

			if A(15 downto 8) = HM2DPLLControl1Addr and writestb = '1' then	 --  
				LoadDPLLControl1 <= '1';
			else
				LoadDPLLControl1 <= '0';
			end if;
			if A(15 downto 8) = HM2DPLLControl1Addr and readstb = '1' then	 --  
				ReadDPLLControl1 <= '1';
			else
				ReadDPLLControl1 <= '0';
			end if;

			if A(15 downto 8) = HM2DPLLTimer12Addr and writestb = '1' then	 --  
				LoadDPLLTimers12 <= '1';
			else
				LoadDPLLTimers12 <= '0';
			end if;
			if A(15 downto 8) = HM2DPLLTimer12Addr and readstb = '1' then	 --  
				ReadDPLLTimers12 <= '1';
			else
				ReadDPLLTimers12 <= '0';
			end if;

			if A(15 downto 8) = HM2DPLLTimer34Addr and writestb = '1' then	 --  
				LoadDPLLTimers34 <= '1';
			else
				LoadDPLLTimers34 <= '0';
			end if;
			if A(15 downto 8) = HM2DPLLTimer34Addr and readstb = '1' then	 --  
				ReadDPLLTimers34 <= '1';
			else
				ReadDPLLTimers34 <= '0';
			end if;

			if A(15 downto 8) = HM2DPLLSyncAddr and writestb = '1' then	 --  
				WriteSyncDPLL <= '1';
			else
				WriteSyncDPLL <= '0';
			end if;
			if A(15 downto 8) = HM2DPLLSyncAddr and readstb = '1' then	 --  
				ReadSyncDPLL <= '1';
			else
				ReadSyncDPLL <= '0';
			end if;
			RateSources <= DPLLTimers&DPLLRefOut;
			rates <= RateSources;
		end process HM2DPLLDecodeProcess;

		DoHM2DPLLPins: process(DPLLTimers,DPLLRefOut)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = HM2DPLLTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	
						when HM2DPLLSyncInPin =>
							DPLLSyncIn <= IOBits(i);
						when HM2DPLLRefOutPin =>
							AltData(i) <= DPLLRefOut;				
						when HM2DPLLTimer1Pin =>
							AltData(i) <= DPLLTimers(0);				
						when HM2DPLLTimer2Pin =>
							AltData(i) <= DPLLTimers(1);				
						when HM2DPLLTimer3Pin =>
							AltData(i) <= DPLLTimers(2);				
						when HM2DPLLTimer4Pin =>
							AltData(i) <= DPLLTimers(3);				
						when others => null;
						
					end case;
				end if;
			end loop;	
		end process;	
	end generate;

			
	makestepgens: if StepGens >0 generate
	signal LoadStepGenRate: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenRate: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenAccum: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenAccum: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenMode: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenMode: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenDSUTime: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenDSUTime: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenDHLDTime: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenDHLDTime: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenPulseATime: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenPulseATime: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenPulseITime: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenPulseITime: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenTableMax: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenTableMax: std_logic_vector(StepGens -1 downto 0);
	signal LoadStepGenTable: std_logic_vector(StepGens -1 downto 0);
	signal ReadStepGenTable: std_logic_vector(StepGens -1 downto 0);
	type StepGenOutType is array(StepGens-1 downto 0) of std_logic_vector(StepGenTableWidth-1 downto 0);
	signal StepGenOut : StepGenOutType;
	signal StepGenIndex: std_logic_vector(StepGens -1 downto 0);
-- Step generator related signals

	signal StepGenRateSel: std_logic;
	signal StepGenAccumSel: std_logic;
	signal StepGenModeSel: std_logic;
	signal StepGenDSUTimeSel: std_logic;
	signal StepGenDHLDTimeSel: std_logic;
	signal StepGenPulseATimeSel: std_logic;
	signal StepGenPulseITimeSel: std_logic;
	signal StepGenTableMaxSel: std_logic;
	signal StepGenTableSel: std_logic;

	
-- Step generators master rate related signals

	signal LoadStepGenBasicRate: std_logic;
	signal ReadStepGenBasicRate: std_logic;
	signal StepGenBasicRate: std_logic;

-- dpll only signals	
	signal StepGenSampleTime: std_logic;
	signal StepGenTimerEnable: std_logic;
	signal LoadStepGenTimerSelect: std_logic;
	signal ReadStepGenTimerSelect: std_logic;
	
	begin
		stepgenprescaler: if HM2DPLLs = 0 generate
			StepRategen : entity work.RateGen port map(
				ibus => ibus,
				obus => obus,
				loadbasicrate => LoadStepGenBasicRate,
				readbasicrate => ReadStepGenBasicRate,
				hold => '0',
				basicrate => StepGenBasicRate,
				clk => clklow);
		end generate;
		stepgenprescalerd: if HM2DPLLs > 0 generate
			StepRategenD : entity work.RateGenD port map(
				ibus => ibus,
				obus => obus,
				loadbasicrate => LoadStepGenBasicRate,
				readbasicrate => ReadStepGenBasicRate,
				loadtimerselect => LoadStepGenTimerSelect,
				readtimerselect => ReadStepGenTimerSelect,
				hold => '0',
				basicrate => StepGenBasicRate,
				timers => RateSources,
				timer => StepGenSampleTime,
				timerenable	=> StepGenTimerEnable,
				clk => clklow);
		end generate;
		
		makestepgens: if HM2DPLLs = 0 generate
			generatestepgens: for i in 0 to StepGens-1 generate
				usg: if not(UseStepgenIndex or UseStepgenProbe) generate
				stepgenx: entity work.stepgen
				generic map (
					buswidth => BusWidth,
					timersize => 14,			-- = ~480 usec at 33 MHz, ~320 at 50 Mhz 
					tablewidth => StepGenTableWidth,
					asize => 48,
					rsize => 32 
					)
				port map (
					clk => clklow,
					ibus => ibus,
					obus 	=>	 obus,
					loadsteprate => LoadStepGenRate(i),
					loadaccum => LoadStepGenAccum(i),
					loadstepmode => LoadStepGenMode(i),
					loaddirsetuptime => LoadStepGenDSUTime(i),
					loaddirholdtime => LoadStepGenDHLDTime(i),
					loadpulseactivetime => LoadStepGenPulseATime(i),
					loadpulseidletime => LoadStepGenPulseITime(i),
					loadtable => LoadStepGenTable(i),
					loadtablemax => LoadStepGenTableMax(i),
					readsteprate => ReadStepGenRate(i),
					readaccum => ReadStepGenAccum(i),
					readstepmode => ReadStepGenMode(i),
					readdirsetuptime => ReadStepGenDSUTime(i),
					readdirholdtime => ReadStepGenDHLDTime(i),
					readpulseactivetime => ReadStepGenPulseATime(i),
					readpulseidletime => ReadStepGenPulseITime(i),
					readtable => ReadStepGenTable(i),
					readtablemax => ReadStepGenTableMax(i),
					basicrate => StepGenBasicRate,
					hold => '0',
					stout => StepGenOut(i)
					);
				end generate usg;
		
				usgi: if (UseStepgenIndex or UseStepgenProbe) generate
				stepgenx: entity work.stepgeni
				generic map (
					buswidth => BusWidth,
					timersize => 14,			-- = ~480 usec at 33 MHz, ~320 at 50 Mhz 
					tablewidth => StepGenTableWidth,
					asize => 48,
					rsize => 32,
					lsize =>16
					)
				port map (
					clk => clklow,
					ibus => ibus,
					obus 	=>	 obus,
					loadsteprate => LoadStepGenRate(i),
					loadaccum => LoadStepGenAccum(i),
					loadstepmode => LoadStepGenMode(i),
					loaddirsetuptime => LoadStepGenDSUTime(i),
					loaddirholdtime => LoadStepGenDHLDTime(i),
					loadpulseactivetime => LoadStepGenPulseATime(i),
					loadpulseidletime => LoadStepGenPulseITime(i),
					loadtable => LoadStepGenTable(i),
					loadtablemax => LoadStepGenTableMax(i),
					readsteprate => ReadStepGenRate(i),
					readaccum => ReadStepGenAccum(i),
					readstepmode => ReadStepGenMode(i),
					readdirsetuptime => ReadStepGenDSUTime(i),
					readdirholdtime => ReadStepGenDHLDTime(i),
					readpulseactivetime => ReadStepGenPulseATime(i),
					readpulseidletime => ReadStepGenPulseITime(i),
					readtable => ReadStepGenTable(i),
					readtablemax => ReadStepGenTableMax(i),
					basicrate => StepGenBasicRate,
					hold => '0',
					index => StepGenIndex(i),
					probe => probe,
					stout => StepGenOut(i)
					);
				end generate usgi;
			end generate generatestepgens;
		end generate;
		
		makestepgends: if HM2DPLLs > 0 generate
			generatestepgends: for i in 0 to StepGens-1 generate
				usgd: if not(UseStepgenIndex or UseStepgenProbe) generate
				stepgenx: entity work.stepgend
				generic map (
					buswidth => BusWidth,
					timersize => 14,			-- = ~480 usec at 33 MHz, ~320 at 50 Mhz 
					tablewidth => StepGenTableWidth,
					asize => 48,
					rsize => 32 
					)
				port map (
					clk => clklow,
					ibus => ibus,
					obus 	=>	 obus,
					loadsteprate => LoadStepGenRate(i),
					loadaccum => LoadStepGenAccum(i),
					loadstepmode => LoadStepGenMode(i),
					loaddirsetuptime => LoadStepGenDSUTime(i),
					loaddirholdtime => LoadStepGenDHLDTime(i),
					loadpulseactivetime => LoadStepGenPulseATime(i),
					loadpulseidletime => LoadStepGenPulseITime(i),
					loadtable => LoadStepGenTable(i),
					loadtablemax => LoadStepGenTableMax(i),
					readsteprate => ReadStepGenRate(i),
					readaccum => ReadStepGenAccum(i),
					readstepmode => ReadStepGenMode(i),
					readdirsetuptime => ReadStepGenDSUTime(i),
					readdirholdtime => ReadStepGenDHLDTime(i),
					readpulseactivetime => ReadStepGenPulseATime(i),
					readpulseidletime => ReadStepGenPulseITime(i),
					readtable => ReadStepGenTable(i),
					readtablemax => ReadStepGenTableMax(i),
					basicrate => StepGenBasicRate,
					hold => '0',
					timer => StepGenSampleTime,
					timerenable	=> StepGenTimerEnable,
					stout => StepGenOut(i)
					);
				end generate usgd;

				usgid: if (UseStepgenIndex or UseStepgenProbe) generate
				stepgenx: entity work.stepgenid
				generic map (
					buswidth => BusWidth,
					timersize => 14,			-- = ~480 usec at 33 MHz, ~320 at 50 Mhz 
					tablewidth => StepGenTableWidth,
					asize => 48,
					rsize => 32,
					lsize =>16
					)
				port map (
					clk => clklow,
					ibus => ibus,
					obus 	=>	 obus,
					loadsteprate => LoadStepGenRate(i),
					loadaccum => LoadStepGenAccum(i),
					loadstepmode => LoadStepGenMode(i),
					loaddirsetuptime => LoadStepGenDSUTime(i),
					loaddirholdtime => LoadStepGenDHLDTime(i),
					loadpulseactivetime => LoadStepGenPulseATime(i),
					loadpulseidletime => LoadStepGenPulseITime(i),
					loadtable => LoadStepGenTable(i),
					loadtablemax => LoadStepGenTableMax(i),
					readsteprate => ReadStepGenRate(i),
					readaccum => ReadStepGenAccum(i),
					readstepmode => ReadStepGenMode(i),
					readdirsetuptime => ReadStepGenDSUTime(i),
					readdirholdtime => ReadStepGenDHLDTime(i),
					readpulseactivetime => ReadStepGenPulseATime(i),
					readpulseidletime => ReadStepGenPulseITime(i),
					readtable => ReadStepGenTable(i),
					readtablemax => ReadStepGenTableMax(i),
					basicrate => StepGenBasicRate,
					hold => '0',
					index => StepGenIndex(i),
					probe => probe,
					timer => StepGenSampleTime,
					timerenable	=> StepGenTimerEnable,
					stout => StepGenOut(i)
					);
				end generate usgid;
			end generate generatestepgends;
		end generate;
		
		StepGenDecodeProcess : process (A,readstb,writestb,StepGenRateSel, StepGenAccumSel, StepGenModeSel,
                                 			StepGenDSUTimeSel, StepGenDHLDTimeSel, StepGenPulseATimeSel, 
			                                 StepGenPulseITimeSel, StepGenTableSel, StepGenTableMaxSel)
		begin
			if A(15 downto 8) = StepGenRateAddr then	 --  stepgen rate register select
				StepGenRateSel <= '1';
			else
				StepGenRateSel <= '0';
			end if;
			if A(15 downto 8) = StepGenAccumAddr then	 --  stepgen Accumumlator low select
				StepGenAccumSel <= '1';
			else
				StepGenAccumSel <= '0';
			end if;
			if A(15 downto 8) = StepGenModeAddr then	 --  stepgen mode register select
				StepGenModeSel <= '1';
			else
				StepGenModeSel <= '0';
			end if;
			if A(15 downto 8) = StepGenDSUTimeAddr then	 --  stepgen Dir setup time register select
				StepGenDSUTimeSel <= '1';
			else
				StepGenDSUTimeSel <= '0';
			end if;
			if A(15 downto 8) =StepGenDHLDTimeAddr then	 --  stepgen Dir hold time register select
				StepGenDHLDTimeSel <= '1';
			else
				StepGenDHLDTimeSel <= '0';
			end if;
			if A(15 downto 8) = StepGenPulseATimeAddr then	 --  stepgen pulse width register select
				StepGenPulseATimeSel <= '1';
			else
				StepGenPulseATimeSel <= '0';
			end if;
			if A(15 downto 8) = StepGenPulseITimeAddr then	 --  stepgen pulse width register select
				StepGenPulseITimeSel <= '1';
			else
				StepGenPulseITimeSel <= '0';
			end if;
			if A(15 downto 8) = StepGenTableAddr then	 --  stepgen pulse width register select
				StepGenTableSel <= '1';
			else
				StepGenTableSel <= '0';
			end if;
			if A(15 downto 8) = StepGenTableMaxAddr then	 --  stepgen pulse width register select
				StepGenTableMaxSel <= '1';
			else
				StepGenTableMaxSel <= '0';
			end if;

			if A(15 downto 8) = StepGenBasicRateAddr and writestb = '1' then	 --  
				LoadStepGenBasicRate <= '1';
			else
				LoadStepGenBasicRate <= '0';
			end if;
			if A(15 downto 8) = StepGenBasicRateAddr and readstb = '1' then	 --  
				ReadStepGenBasicRate <= '1';
			else
				ReadStepGenBasicRate <= '0';
			end if;			
		
			if A(15 downto 8) = StepGenTimerSelectAddr and writestb = '1' then	 --  
				LoadStepGenTimerSelect <= '1';
			else
				LoadStepGenTimerSelect <= '0';
			end if;
			if A(15 downto 8) = StepGenTimerSelectAddr and readstb = '1' then	 --  
				ReadStepGenTimerSelect <= '1';
			else
				ReadStepGenTimerSelect <= '0';
			end if;		
			
			LoadStepGenRate <= OneOfNDecode(STEPGENs,StepGenRateSel,writestb,A(7 downto 2)); 	-- 64 max
			ReadStepGenRate <= OneOfNDecode(STEPGENs,StepGenRateSel,readstb,A(7 downto 2)); 		-- Note: all the reads are decoded here
			LoadStepGenAccum <= OneOfNDecode(STEPGENs,StepGenAccumSel,writestb,A(7 downto 2));	-- but most are commented out in the 
			ReadStepGenAccum <= OneOfNDecode(STEPGENs,StepGenAccumSel,readstb,A(7 downto 2));	-- stepgen module hardware for space reasons
			LoadStepGenMode <= OneOfNDecode(STEPGENs,StepGenModeSel,writestb,A(7 downto 2));			 
			ReadStepGenMode <= OneOfNDecode(STEPGENs,StepGenModeSel,Readstb,A(7 downto 2));	
			LoadStepGenDSUTime <= OneOfNDecode(STEPGENs,StepGenDSUTimeSel,writestb,A(7 downto 2));
			ReadStepGenDSUTime <= OneOfNDecode(STEPGENs,StepGenDSUTimeSel,Readstb,A(7 downto 2));
			LoadStepGenDHLDTime <= OneOfNDecode(STEPGENs,StepGenDHLDTimeSel,writestb,A(7 downto 2));
			ReadStepGenDHLDTime <= OneOfNDecode(STEPGENs,StepGenDHLDTimeSel,Readstb,A(7 downto 2));
			LoadStepGenPulseATime <= OneOfNDecode(STEPGENs,StepGenPulseATimeSel,writestb,A(7 downto 2));
			ReadStepGenPulseATime <= OneOfNDecode(STEPGENs,StepGenPulseATimeSel,Readstb,A(7 downto 2));
			LoadStepGenPulseITime <= OneOfNDecode(STEPGENs,StepGenPulseITimeSel,writestb,A(7 downto 2));
			ReadStepGenPulseITime <= OneOfNDecode(STEPGENs,StepGenPulseITimeSel,Readstb,A(7 downto 2));
			LoadStepGenTable <= OneOfNDecode(STEPGENs,StepGenTableSel,writestb,A(7 downto 2));
			ReadStepGenTable <= OneOfNDecode(STEPGENs,StepGenTableSel,Readstb,A(7 downto 2));
			LoadStepGenTableMax <= OneOfNDecode(STEPGENs,StepGenTableMaxSel,writestb,A(7 downto 2));
			ReadStepGenTableMax <= OneOfNDecode(STEPGENs,StepGenTableMaxSel,Readstb,A(7 downto 2));
		end process StepGenDecodeProcess;
		
		DoStepgenPins: process(IOBits,StepGenOut)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = StepGenTag then											
					if (ThePinDesc(i)(7 downto 0) and x"80") /= 0 then -- only for outputs 
						AltData(i) <= StepGenOut(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(6 downto 0))-1);						
					end if;
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when StepGenIndexPin =>
							StepGenIndex(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when StepGenProbePin =>
							Probe <= IOBits(i);	-- only 1 please!
						when others => null;
					end case;
				end if;
			end loop;
		end process;
		
	end generate makestepgens;


	makeqcounters: if QCounters >0 generate
	signal LoadQCounter: std_logic_vector(QCounters-1 downto 0);
	signal ReadQCounter: std_logic_vector(QCounters-1 downto 0);
	signal LoadQCounterCCR: std_logic_vector(QCounters-1 downto 0);
	signal ReadQCounterCCR: std_logic_vector(QCounters-1 downto 0);
	signal QuadA: std_logic_vector(QCounters-1 downto 0);
	signal QuadB: std_logic_vector(QCounters-1 downto 0);
	signal Index: std_logic_vector(QCounters -1 downto 0);
	signal IndexMask: std_logic_vector(QCounters -1 downto 0);
	signal QCounterSel : std_logic;
	signal QCounterCCRSel : std_logic;
	signal LoadTSDiv : std_logic;
	signal ReadTSDiv : std_logic;
	signal ReadTS : std_logic;
	signal TimeStampBus: std_logic_vector(15 downto 0);
	signal LoadQCountRate : std_logic;
	signal QCountFilterRate : std_logic;	

-- dpll only signals	
	signal QCounterDPLLSampleTime: std_logic;
	signal QcounterTimerEnable: std_logic;
	signal LoadQCounterTimerSelect: std_logic;
	signal ReadQCounterTimerSelect: std_logic;
	
	begin
		timestampx: entity work.timestamp 
			port map( 
				ibus => ibus(15 downto 0),
				obus => obus(15 downto 0),
				loadtsdiv => LoadTSDiv ,
				readts => ReadTS,
				readtsdiv =>ReadTSDiv,
				tscount => TimeStampBus,
				clk => clklow
			);
				
		nodpllqcrate: if HM2DPLLs = 0 generate
			qcountratex: entity work.qcounterate
				generic map (clock => ClockLow) -- default encoder clock is 16 MHz
				port map( 
					ibus => ibus(11 downto 0),
					loadRate => LoadQCountRate,
					rateout => QcountFilterRate,
					clk => clklow
				);	
		end generate nodpllqcrate;
		
		dpllqcrate: if HM2DPLLs > 0 generate
			qcountratedx: entity work.qcounterated
				generic map (clock => ClockLow) -- default encoder clock is 16 MHz
				port map( 
					ibus => ibus,
					obus => obus,
					loadRate => LoadQCountRate,
					loadtimerselect => LoadQCounterTimerSelect,
					readtimerselect => ReadQCounterTimerSelect,
					timers => RateSources,
					timer => QCounterDPLLSampleTime,
					timerenable	=> QcounterTimerEnable,
					rateout => QcountFilterRate,
					clk => clklow
				);				
		end generate dpllqcrate;		
		
		nuseprobe1: if not UseProbe generate
			nodpllqcounters: if HM2DPLLs = 0 generate
				makequadcounters: for i in 0 to QCounters-1 generate
					qcounterx: entity work.qcounter 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => QuadA(i),
						quadb => QuadB(i),
						index => Index(i),
						loadccr => LoadQcounterCCR(i),
						readccr => ReadQcounterCCR(i),
						readcount => ReadQcounter(i),
						countclear => LoadQcounter(i),
						timestamp => TimeStampBus,
						indexmask => IndexMask(i),
						filterrate => QCountFilterRate,
						clk =>	clklow
					);
				end generate makequadcounters;
			end generate nodpllqcounters;
			
			dpllqcounters: if HM2DPLLs > 0 generate
				makequadcountersd: for i in 0 to QCounters-1 generate
					qcounterxd: entity work.qcounterd 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => QuadA(i),
						quadb => QuadB(i),
						index => Index(i),
						loadccr => LoadQcounterCCR(i),
						readccr => ReadQcounterCCR(i),
						readcount => ReadQcounter(i),
						countclear => LoadQcounter(i),
						timestamp => TimeStampBus,
						indexmask => IndexMask(i),
						filterrate => QCountFilterRate,
						timer => QCounterDPLLSampleTime,
						timerenable	=> QcounterTimerEnable,
						clk =>	clklow
					);
				end generate makequadcountersd;
			end generate dpllqcounters;
		end generate nuseprobe1;

		useprobe1: if UseProbe generate
			nodpllqcountersp: if HM2DPLLs = 0 generate
				makequadcountersp: for i in 0 to QCounters-1 generate
					qcounterxp: entity work.qcounterp 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => QuadA(i),
						quadb => QuadB(i),
						index => Index(i),
						loadccr => LoadQcounterCCR(i),
						readccr => ReadQcounterCCR(i),
						readcount => ReadQcounter(i),
						countclear => LoadQcounter(i),
						timestamp => TimeStampBus,
						indexmask => IndexMask(i),
						filterrate => QCountFilterRate,
						probe => Probe,
						clk =>	clklow
					);
				end generate makequadcountersp;
			end generate nodpllqcountersp;
			
			dpllqcountersp: if HM2DPLLs > 0 generate
				makequadcounterspd: for i in 0 to QCounters-1 generate
					qcounterxpd: entity work.qcounterpd 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => QuadA(i),
						quadb => QuadB(i),
						index => Index(i),
						loadccr => LoadQcounterCCR(i),
						readccr => ReadQcounterCCR(i),
						readcount => ReadQcounter(i),
						countclear => LoadQcounter(i),
						timestamp => TimeStampBus,
						indexmask => IndexMask(i),
						filterrate => QCountFilterRate,
						probe => Probe,
						timer => QCounterDPLLSampleTime,
						timerenable	=> QcounterTimerEnable,
						clk =>	clklow
					);
				end generate makequadcounterspd;
			end generate dpllqcountersp;
		end generate useprobe1;
	
		QCounterDecodeProcess : process (A,Readstb,writestb,QCounterSel, QCounterCCRSel)
		begin
			if A(15 downto 8) = QCounterAddr then	 --  QCounter select
				QCounterSel <= '1';
			else
				QCounterSel <= '0';
			end if;
			if A(15 downto 8) = QCounterCCRAddr then	 --  QCounter CCR register select
				QCounterCCRSel <= '1';
			else
				QCounterCCRSel <= '0';
			end if;			
			if A(15 downto 8) = TSDivAddr and writestb = '1' then	 --  
				LoadTSDiv <= '1';
			else
				LoadTSDiv <= '0';
			end if;		
			if A(15 downto 8) = TSDivAddr and readstb = '1' then	 --  
				ReadTSDiv <= '1';
			else
				ReadTSDiv <= '0';
			end if;
			if A(15 downto 8) = TSAddr and readstb = '1' then	 --  
				ReadTS <= '1';
			else
				ReadTS <= '0';
			end if;
			if A(15 downto 8) = QCRateAddr and writestb = '1' then	 --  
				LoadQCountRate <= '1';
			else
				LoadQCountRate <= '0';
			end if;

			if A(15 downto 8) = QCtimerSelectAddr and writestb = '1' then	 --  
				LoadQCounterTimerSelect <= '1';
			else
				LoadQcounterTimerSelect <= '0';
			end if;
			if A(15 downto 8) = QCtimerSelectAddr and readstb = '1' then	 --  
				ReadQCounterTimerSelect <= '1';
			else
				ReadQCounterTimerSelect <= '0';
			end if;		

			LoadQCounter <= OneOfNDecode(QCounters,QCounterSel,writestb,A(7 downto 2));  -- 64 max
			ReadQCounter <= OneOfNDecode(QCounters,QCounterSel,Readstb,A(7 downto 2));
			LoadQCounterCCR <= OneOfNDecode(QCounters,QCounterCCRSel,writestb,A(7 downto 2));
			ReadQCounterCCR <= OneOfNDecode(QCounters,QCounterCCRSel,Readstb,A(7 downto 2));
		end process QCounterDecodeProcess;

		DoQCounterPins: process(IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = QCountTag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when QCountQAPin =>
							QuadA(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i); 
						when QCountQBPin =>
							QuadB(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when QCountIdxPin =>
							Index(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when QCountIdxMaskPin =>
							IndexMask(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when QCountProbePin =>
							Probe <= IOBits(i);	-- only 1 please!
						when others => null;
					end case;
				end if;
			end loop;
		end process;		

	end generate makeqcounters;
	
	makemuxedqcounters: if MuxedQCounters >0 generate	
	signal LoadMuxedQCounter: std_logic_vector(MuxedQCounters-1 downto 0);
	signal ReadMuxedQCounter: std_logic_vector(MuxedQCounters-1 downto 0);
	signal LoadMuxedQCounterCCR: std_logic_vector(MuxedQCounters-1 downto 0);
	signal ReadMuxedQCounterCCR: std_logic_vector(MuxedQCounters-1 downto 0);
	signal MuxedQuadA: std_logic_vector(MuxedQCounters/2 -1 downto 0); -- 2 should be muxdepth constant?
	signal MuxedQuadB: std_logic_vector(MuxedQCounters/2 -1 downto 0);
	signal MuxedIndex: std_logic_vector(MuxedQCounters/2 -1 downto 0);
	signal MuxedIndexMask: std_logic_vector(MuxedQCounters -1 downto 0);	
	signal MuxedIndexMaskMIM: std_logic_vector(MuxedQCountersMIM/2 -1 downto 0);	
	signal DemuxedIndexMask: std_logic_vector(MuxedQCountersMIM -1 downto 0);	
	signal DeMuxedQuadA: std_logic_vector(MuxedQCounters -1 downto 0);
	signal DeMuxedQuadB: std_logic_vector(MuxedQCounters -1 downto 0);
	signal DeMuxedIndex: std_logic_vector(MuxedQCounters -1 downto 0);	
	signal MuxedQCounterSel : std_logic;
	signal MuxedQCounterCCRSel : std_logic;
	signal MuxedProbe : std_logic; -- only 1!
	signal LoadMuxedTSDiv : std_logic;
	signal ReadMuxedTSDiv : std_logic;
	signal ReadMuxedTS : std_logic;
	signal MuxedTimeStampBus: std_logic_vector(15 downto 0);
	signal LoadMuxedQCountRate : std_logic;
	signal MuxedQCountFilterRate : std_logic;	
	signal PrePreMuxedQctrSel : std_logic_vector(1 downto 0);
	signal PreMuxedQctrSel : std_logic_vector(1 downto 0);
	signal MuxedQCtrSel : std_logic_vector(1 downto 0);
	signal PreMuxedQCtrSampleTime : std_logic_vector(1 downto 0);
	signal MuxedQCtrSampleTime : std_logic_vector(1 downto 0);
	signal MuxedQCountDeskew : std_logic_vector(3 downto 0);	

-- dpll only signals	
	signal MuxedQCtrDPLLSampleTime: std_logic;
	signal MuxedQCtrTimerEnable: std_logic;
	signal LoadMuxedQCtrTimerSelect: std_logic;
	signal ReadMuxedQCtrTimerSelect: std_logic;

	begin
		timestampx: entity work.timestamp 
			port map( 
				ibus => ibus(15 downto 0),
				obus => obus(15 downto 0),
				loadtsdiv => LoadMuxedTSDiv,
				readts => ReadMuxedTS,
				readtsdiv => ReadMuxedTSDiv,
				tscount => MuxedTimeStampBus,
				clk => clklow
			);				

		nodpllqcratem: if HM2DPLLs = 0 generate
			qcountratemx: entity work.qcounteratesk
				generic map (clock => ClockLow) -- default encoder clock is 16 MHz
				port map( 
					ibus => ibus,
					loadRate => LoadMuxedQCountRate,
					rateout => MuxedQcountFilterRate,
					clk => clklow
				);	
		end generate nodpllqcratem;
		
		dpllqcratem: if HM2DPLLs > 0 generate
			qcountratemdx: entity work.qcounterateskd
				generic map (clock => ClockLow) -- default encoder clock is 16 MHz
				port map( 
					ibus => ibus,
					obus => obus,
					loadRate => LoadMuxedQCountRate,
					loadtimerselect => LoadMuxedQCtrTimerSelect,
					readtimerselect => ReadMuxedQCtrTimerSelect,
					timers => RateSources,
					timer => MuxedQCtrDPLLSampleTime,
					timerenable	=> MuxedQCtrTimerEnable,
					rateout => MuxedQcountFilterRate,
					deskewout => MuxedQCountDeskew,
					clk => clklow
				);				
		end generate dpllqcratem;
		
		qcountermuxdeskew: entity work.srl16delay
			generic map ( width => 2)
			port map (
			   clk => clklow,
				dlyin => PrePreMuxedQCtrSel,
				dlyout => PreMuxedQCtrSampleTime,
				delay => MuxedQCountDeskew
			);
			
		nuseprobe2: if not UseMuxedProbe generate
			nodpllmuxedqcounters: if HM2DPLLs = 0 generate
				makemuxedquadcounters: for i in 0 to MuxedQCounters-1 generate
					qcounterx: entity work.qcounter 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => MuxedIndexMask(i),
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcounters;
			end generate nodpllmuxedqcounters;
			
			dpllmuxedqcounters: if HM2DPLLs > 0 generate
				makemuxedquadcountersd: for i in 0 to MuxedQCounters-1 generate
					qcounterx: entity work.qcounterd 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => MuxedIndexMask(i),
						timer => MuxedQCtrDPLLSampleTime,
						timerenable	=> MuxedQCtrTimerEnable,
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcountersd;
			end generate dpllmuxedqcounters;
		end generate nuseprobe2;

		useprobe2: if UseMuxedProbe generate
			nodpllmuxedqcountersp: if HM2DPLLs = 0 generate
				makemuxedquadcountersp: for i in 0 to MuxedQCounters-1 generate
					qcounterx: entity work.qcounterp 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => MuxedIndexMask(i),
						probe => Probe,
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcountersp;
			end generate nodpllmuxedqcountersp;
			
			dpllmuxedqcountersp: if HM2DPLLs > 0 generate
				makemuxedquadcounterspd: for i in 0 to MuxedQCounters-1 generate
					qcounterx: entity work.qcounterpd 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => MuxedIndexMask(i),
						probe => Probe,
						timer => MuxedQCtrDPLLSampleTime,
						timerenable	=> MuxedQCtrTimerEnable,
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcounterspd;
			end generate dpllmuxedqcountersp;
		end generate useprobe2;
		
		nuseprobe3: if not UseMuxedProbe generate
			nodpllmuxedqcountersmim: if HM2DPLLs = 0 generate
				makemuxedquadcountersmim: for i in 0 to MuxedQCountersMIM-1 generate
					qcounterx: entity work.qcounter 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => DeMuxedIndexMask(i),
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcountersmim;
			end generate nodpllmuxedqcountersmim;
			
			dpllmuxedqcountersmim: if HM2DPLLs > 0 generate
				makemuxedquadcountersmimd: for i in 0 to MuxedQCountersMIM-1 generate
					qcounterx: entity work.qcounterd 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => DeMuxedIndexMask(i),
						timer => MuxedQCtrDPLLSampleTime,
						timerenable	=> MuxedQCtrTimerEnable,
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcountersmimd;
			end generate dpllmuxedqcountersmim;
		end generate nuseprobe3;
	
		useprobe3: if UseMuxedProbe generate
			nodpllmuxedqcountersmimp: if HM2DPLLs = 0 generate
				makemuxedquadcountersmimp: for i in 0 to MuxedQCountersMIM-1 generate
					qcounterx: entity work.qcounterp 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => DeMuxedIndexMask(i),
						probe => Probe,
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcountersmimp;
			end generate nodpllmuxedqcountersmimp;
			
			dpllmuxedqcountersmimp: if HM2DPLLs > 0 generate
				makemuxedquadcountersmimpd: for i in 0 to MuxedQCountersMIM-1 generate
					qcounterx: entity work.qcounterpd 
					generic map (
						buswidth => BusWidth
					)
					port map (
						obus => obus,
						ibus => ibus,
						quada => DemuxedQuadA(i),
						quadb => DemuxedQuadB(i),
						index => DemuxedIndex(i),
						loadccr => LoadMuxedQcounterCCR(i),
						readccr => ReadMuxedQcounterCCR(i),
						readcount => ReadMuxedQcounter(i),
						countclear => LoadMuxedQcounter(i),
						timestamp => MuxedTimeStampBus,
						indexmask => DeMuxedIndexMask(i),
						probe => Probe,
						timer => MuxedQCtrDPLLSampleTime,
						timerenable	=> MuxedQCtrTimerEnable,
						filterrate => MuxedQCountFilterRate,
						clk =>	clklow
						);
				end generate makemuxedquadcountersmimpd;
			end generate dpllmuxedqcountersmimp;
		end generate useprobe3;
	
		
		MuxedQCounterDecodeProcess : process (A,Readstb,writestb,MuxedQCounterSel, MuxedQCounterCCRSel)
		begin
			if A(15 downto 8) = MuxedQCounterAddr then	 --  QCounter select
				MuxedQCounterSel <= '1';
			else
				MuxedQCounterSel <= '0';
			end if;
			if A(15 downto 8) = MuxedQCounterCCRAddr then	 --  QCounter CCR register select
				MuxedQCounterCCRSel <= '1';
			else
				MuxedQCounterCCRSel <= '0';
			end if;
			if A(15 downto 8) = MuxedTSDivAddr and writestb = '1' then	 --  
				LoadMuxedTSDiv <= '1';
			else
				LoadMuxedTSDiv <= '0';
			end if;
			if A(15 downto 8) = MuxedTSDivAddr and readstb = '1' then	 --  
				ReadMuxedTSDiv <= '1';
			else
				ReadMuxedTSDiv <= '0';
			end if;
			if A(15 downto 8) = MuxedTSAddr and readstb = '1' then	 --  
				ReadMuxedTS <= '1';
			else
				ReadMuxedTS <= '0';
			end if;
			if A(15 downto 8) = MuxedQCRateAddr and writestb = '1' then	 --  
				LoadMuxedQCountRate <= '1';
			else
				LoadMuxedQCountRate <= '0';
			end if;

			if A(15 downto 8) = MuxedQCTimerSelectAddr and writestb = '1' then	 --  
				LoadMuxedQCtrTimerSelect <= '1';
			else
				LoadMuxedQCtrTimerSelect <= '0';
			end if;
			if A(15 downto 8) = MuxedQCTimerSelectAddr and readstb = '1' then	 --  
				ReadMuxedQCtrTimerSelect <= '1';
			else
				ReadMuxedQCtrTimerSelect <= '0';
			end if;		

			LoadMuxedQCounter <= OneOfNDecode(MuxedQCounters,MuxedQCounterSel,writestb,A(7 downto 2));  -- 64 max
			ReadMuxedQCounter <= OneOfNDecode(MuxedQCounters,MuxedQCounterSel,Readstb,A(7 downto 2));
			LoadMuxedQCounterCCR <= OneOfNDecode(MuxedQCounters,MuxedQCounterCCRSel,writestb,A(7 downto 2));
			ReadMuxedQCounterCCR <= OneOfNDecode(MuxedQCounters,MuxedQCounterCCRSel,Readstb,A(7 downto 2));
		end process MuxedQCounterDecodeProcess;	

		DoMuxedQCounterPins: process(IOBits,MuxedQCtrSel)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = MuxedQCountTag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when MuxedQCountQAPin =>
							MuxedQuadA(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i); 
						when MuxedQCountQBPin =>
							MuxedQuadB(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when MuxedQCountIdxPin =>
							MuxedIndex(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when MuxedQCountIdxMaskPin =>
							MuxedIndexMask(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when MuxedQCountProbePin =>
							MuxedProbe <= IOBits(i); -- only 1 please!
						when others => null;
					end case;
				end if;
				if ThePinDesc(i)(15 downto 8) = MuxedQCountSelTag then
					case(ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when MuxedQCountSel0Pin =>
							AltData(i) <= MuxedQCtrSel(0);
						when MuxedQCountSel1Pin =>
							AltData(i) <= MuxedQCtrSel(1);
						when others => null;
					end case;
				end if;
			end loop;
		end process;
		
		EncoderDeMux: process(clklow)
		begin
			if rising_edge(clklow) then
				if MuxedQCountFilterRate = '1' then
					PrePreMuxedQCtrSel <= PrePreMuxedQCtrSel + 1;
				end if;
				PreMuxedQCtrSel <= PrePreMuxedQCtrSel;
				MuxedQCtrSel <= PreMuxedQCtrSel;		-- the external mux pin
				MuxedQCtrSampleTime <= PreMuxedQCtrSampleTime;	
				for i in 0 to ((MuxedQCounters/2) -1) loop -- just 2 deep for now
					if PreMuxedQCtrSampleTime(0) = '1' and MuxedQCtrSampleTime(0) = '0' then	-- latch the even inputs	
						DeMuxedQuadA(2*i) <= MuxedQuadA(i);
						DeMuxedQuadB(2*i) <= MuxedQuadB(i);
						DeMuxedIndex(2*i) <= MuxedIndex(i);
					end if;
					if PreMuxedQCtrSampleTime(0) = '0' and MuxedQCtrSampleTime(0) = '1' then	-- latch the odd inputs
						DeMuxedQuadA(2*i+1) <= MuxedQuadA(i);
						DeMuxedQuadB(2*i+1) <= MuxedQuadB(i);
						DeMuxedIndex(2*i+1) <= MuxedIndex(i);
					end if;
				end loop;
			end if; -- clk
		end process;		

	end generate makemuxedqcounters;
	
	makepwms:  if PWMGens > 0 generate	
	signal LoadPWMVal: std_logic_vector(PWMGens -1 downto 0);
	signal LoadPWMCR: std_logic_vector(PWMGens -1 downto 0);
	signal PWMGenOutA: std_logic_vector(PWMGens -1 downto 0);
	signal PWMGenOutB: std_logic_vector(PWMGens -1 downto 0);
	signal PWMGenOutC: std_logic_vector(PWMGens -1 downto 0);
   signal NumberOfPWMS : integer;
	signal LoadPWMRate : std_logic;
	signal LoadPDMRate : std_logic;
	signal PDMRate : std_logic;
	signal PWMValSel : std_logic;
	signal PWMCRSel : std_logic;
	signal LoadPWMEnas: std_logic;
	signal ReadPWMEnas: std_logic;	
	begin
		pwmref : entity work.pwmrefh
		generic map ( 
			buswidth => 16,
			refwidth => PWMRefWidth			-- Normally 13	for 12,11,10, and 9 bit PWM resolutions = 25KHz,50KHz,100KHz,200KHz max. Freq
			)
		port map (
			clk => clklow,
			hclk => clkhigh,
			refcount	=> RefCountBus,
			ibus => ibus(15 downto 0),
			pdmrate => PDMRate,
			pwmrateload => LoadPWMRate,
			pdmrateload => LoadPDMRate
			);	
	makepwmena:  if  UsePWMEnas generate
		PWMEnaReg : entity work.boutreg 
			generic map (
				size => PWMGens,
				buswidth => BusWidth,
				invert => true			-- Must be true! got changed to false somehow 
				)
			port map (
				clk  => clklow,
				ibus => ibus,
				obus => obus,
				load => LoadPWMEnas,
				read => ReadPWMEnas,
				clear => '0',
				dout => PWMGenOutC
				);  		
		end generate makepwmena;
	
	makepwmgens : for i in 0 to PWMGens-1 generate
		pwmgenx: entity work.pwmpdmgenh
		generic map ( 
			buswidth => BusWidth,
			refwidth => PWMRefWidth			-- Normally 13 for 12,11,10, and 9 bit PWM resolutions = 25KHz,50KHz,100KHz,200KHz max. Freq
			)
		port map (
			clk => clklow,
			hclk => clkhigh,
			refcount	=> RefCountBus,
			ibus => ibus,
			loadpwmval => LoadPWMVal(i),
			pcrloadcmd => LoadPWMCR(i),
			pdmrate => PDMRate,
			pwmouta => PWMGenOutA(i),
			pwmoutb => PWMGenOutB(i)
			);		
		end generate;
		
		PWMDecodeProcess : process (A,Readstb,writestb,PWMValSel, PWMCRSel)
		begin
			if A(15 downto 8) = PWMRateAddr and writestb = '1' then	 --  
				LoadPWMRate <= '1';
			else
				LoadPWMRate <= '0';
			end if;
			if A(15 downto 8) = PDMRateAddr and writestb = '1' then	 --  
				LoadPDMRate <= '1';
			else
				LoadPDMRate <= '0';
			end if;
			if A(15 downto 8) = PWMEnasAddr and writestb = '1' then	 --  
				LoadPWMEnas <= '1';
			else
				LoadPWMEnas <= '0';
			end if;
			if A(15 downto 8) = PWMEnasAddr and readstb = '1' then	 --  
				ReadPWMEnas <= '1';
			else
				ReadPWMEnas <= '0';
			end if;
			if A(15 downto 8) = PWMValAddr then	 --  PWMVal select
				PWMValSel <= '1';
			else
				PWMValSel <= '0';
			end if;
			if A(15 downto 8) = PWMCRAddr then	 --  PWM mode register select
				PWMCRSel <= '1';
			else
				PWMCRSel <= '0';
			end if;
			LoadPWMVal <= OneOfNDecode(PWMGENs,PWMValSel,writestb,A(7 downto 2)); -- 64 max
			LoadPWMCR <= OneOfNDecode(PWMGENs,PWMCRSel,writestb,A(7 downto 2));
		end process PWMDecodeProcess;
		
		DoPWMPins: process(PWMGenOutA,PWMGenOutB,PWMGenOutC)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = PWMTag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when PWMAOutPin =>
							AltData(i) <= PWMGENOutA(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when PWMBDirPin =>
							AltData(i) <= PWMGENOutB(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when PWMCEnaPin =>
							AltData(i) <= PWMGENOutC(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when others => null;
					end case;
				end if;
			end loop;
		end process;						
	end generate makepwms;

	
	maketppwmref:  if (TPPWMGens > 0) generate
	signal LoadTPPWMVal: std_logic_vector(TPPWMGens -1 downto 0);
	signal LoadTPPWMENA: std_logic_vector(TPPWMGens -1 downto 0);
	signal ReadTPPWMENA: std_logic_vector(TPPWMGens -1 downto 0);
	signal LoadTPPWMDZ: std_logic_vector(TPPWMGens -1 downto 0);
	signal TPPWMGenOutA: std_logic_vector(TPPWMGens -1 downto 0);
	signal TPPWMGenOutB: std_logic_vector(TPPWMGens -1 downto 0);
	signal TPPWMGenOutC: std_logic_vector(TPPWMGens -1 downto 0);
	signal NTPPWMGenOutA: std_logic_vector(TPPWMGens -1 downto 0);
	signal NTPPWMGenOutB: std_logic_vector(TPPWMGens -1 downto 0);
	signal NTPPWMGenOutC: std_logic_vector(TPPWMGens -1 downto 0);
	signal TPPWMEna: std_logic_vector(TPPWMGens -1 downto 0);
	signal TPPWMFault: std_logic_vector(TPPWMGens -1 downto 0);
	signal TPPWMSample: std_logic_vector(TPPWMGens -1 downto 0);
	signal LoadTPPWMRate : std_logic;
	signal TPRefCountBus : std_logic_vector(10 downto 0);
	signal TPPWMValSel : std_logic;
	signal TPPWMEnaSel : std_logic;
	signal TPPWMDZSel : std_logic;
	begin
		tppwmref : entity work.pwmrefh
		generic map ( 
			buswidth => 16,
			refwidth => 11			-- always 11 for TPPWM 
			)
		port map (
			clk => clklow,
			hclk => clkhigh,
			refcount	=> TPRefCountBus,
			ibus => ibus(15 downto 0),
			pwmrateload => LoadTPPWMRate,
			pdmrateload => '0'
			);	
	
		maketppwmgens : for i in 0 to TPPWMGens-1 generate
			tppwmgenx: entity work.threephasepwm
			port map (
				clk => clklow,
				hclk => clkhigh,
				refcount	=> TPRefCountBus,
				ibus => ibus,
				obus => obus,
				loadpwmreg => LoadTPPWMVal(i),
				loadenareg => LoadTPPWMENA(i),
				readenareg => ReadTPPWMENA(i),
				loaddzreg => LoadTPPWMDZ(i),
				pwmouta => TPPWMGenOutA(i),
				pwmoutb => TPPWMGenOutB(i),
				pwmoutc => TPPWMGenOutC(i),
				npwmouta => NTPPWMGenOutA(i),
				npwmoutb => NTPPWMGenOutB(i),
				npwmoutc => NTPPWMGenOutC(i),
				pwmenaout => TPPWMEna(i),
				pwmfault => TPPWMFault(i),
				pwmsample => TPPWMSample(i)
				
				);
		end generate;	
		
		TPPWMDecodeProcess : process (A,Readstb,writestb,TPPWMValSel, TPPWMEnaSel,TPPWMDZSel)
		begin
			if A(15 downto 8) = TPPWMValAddr then	 --  TPPWMVal select
				TPPWMValSel <= '1';
			else
				TPPWMValSel <= '0';
			end if;
			if A(15 downto 8) = TPPWMEnaAddr then	 --  TPPWM mode register select
				TPPWMEnaSel <= '1';
			else
				TPPWMEnaSel <= '0';
			end if;
			if A(15 downto 8) = TPPWMDZAddr then	 --  TPPWMDZ mode register select
				TPPWMDZSel <= '1';
			else
				TPPWMDZSel <= '0';
			end if;
			if A(15 downto 8) = TPPWMRateAddr and writestb = '1' then	 --  
				LoadTPPWMRate <= '1';
			else
				LoadTPPWMRate <= '0';
			end if;
			LoadTPPWMVal <= OneOfNDecode(TPPWMGENs,TPPWMValSel,writestb,A(7 downto 2)); -- 64 max
			LoadTPPWMEna <= OneOfNDecode(TPPWMGENs,TPPWMEnaSel,writestb,A(7 downto 2));
			ReadTPPWMEna <= OneOfNDecode(TPPWMGENs,TPPWMEnaSel,Readstb,A(7 downto 2));
			LoadTPPWMDZ <= OneOfNDecode(TPPWMGENs,TPPWMDZSel,writestb,A(7 downto 2));
		end process TPPWMDecodeProcess;

		DoTPPWMPins: process(TPPWMGenOutA,TPPWMGenOutB,TPPWMGenOutC,
									NTPPWMGenOutA,NTPPWMGenOutB,NTPPWMGenOutC,TPPWMEna)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = TPPWMTag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when TPPWMAOutPin =>
							AltData(i) <= TPPWMGENOutA(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when TPPWMBOutPin =>
							AltData(i) <= TPPWMGENOutB(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when TPPWMCOutPin =>
							AltData(i) <= TPPWMGENOutC(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when NTPPWMAOutPin =>
							AltData(i) <= NTPPWMGENOutA(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when NTPPWMBOutPin =>
							AltData(i) <= NTPPWMGENOutB(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when NTPPWMCOutPin =>
							AltData(i) <= NTPPWMGENOutC(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when TPPWMEnaPin =>
							AltData(i) <= TPPWMEna(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when TPPWMFaultPin =>
							TPPWMFault(conv_integer(ThePinDesc(i)(23 downto 16))) <= iobits(i); 
						when others => null;
					end case;		
				end if;
			end loop;
		end process;		
	end generate;
	
	makespimod:  if SPIs >0  generate	
	signal LoadSPIBitCount: std_logic_vector(SPIs -1 downto 0);
	signal LoadSPIBitRate: std_logic_vector(SPIs -1 downto 0);
	signal LoadSPIData: std_logic_vector(SPIs -1 downto 0);
	signal ReadSPIData: std_logic_vector(SPIs -1 downto 0);           
	signal ReadSPIBitCOunt: std_logic_vector(SPIs -1 downto 0);
	signal ReadSPIBitRate: std_logic_vector(SPIs -1 downto 0);
	signal SPIClk: std_logic_vector(SPIs -1 downto 0);
	signal SPIIn: std_logic_vector(SPIs -1 downto 0);
	signal SPIOut: std_logic_vector(SPIs -1 downto 0);
	signal SPIFrame: std_logic_vector(SPIs -1 downto 0);
	signal SPIDAV: std_logic_vector(SPIs -1 downto 0);	
	signal SPIBitCountSel : std_logic;
	signal SPIBitrateSel : std_logic;
	signal SPIDataSel : std_logic;	
	
	begin
		makespis: for i in 0 to SPIs -1 generate
			aspi: entity work.SimpleSPI
			generic map (
				buswidth => BusWidth)		
			port map (
				clk  => clklow,
				ibus => ibus,
				obus => obus,
				loadbitcount => LoadSPIBitCount(i),
				loadbitrate => LoadSPIBitRate(i),
				loaddata => LoadSPIData(i),
				readdata => ReadSPIData(i),           
				readbitcount => ReadSPIBitCOunt(i),
				readbitrate => ReadSPIBitRate(i),
				spiclk => SPIClk(i),
				spiin => SPIIn(i),
				spiout => SPIOut(i),
				spiframe => SPIFrame(i),
				davout => SPIDAV(i)
				);
		end generate;	

		SPIDecodeProcess : process (A,Readstb,writestb,SPIDataSel,SPIBitCountSel,SPIBitRateSel)
		begin		
			if A(15 downto 8) = SPIDataAddr then	 --  SPI data register select
				SPIDataSel <= '1';
			else
				SPIDataSel <= '0';
			end if;	
			if A(15 downto 8) = SPIBitCountAddr then	 --  SPI bit count register select
				SPIBitCountSel <= '1';
			else
				SPIBitCountSel <= '0';
			end if;
			if A(15 downto 8) = SPIBitrateAddr then	 --  SPI bit rate register select
				SPIBitrateSel <= '1';
			else
				SPIBitrateSel <= '0';
			end if;
			LoadSPIData <= OneOfNDecode(SPIs,SPIDataSel,writestb,A(5 downto 2)); -- 16 max
			ReadSPIData <= OneOfNDecode(SPIs,SPIDataSel,Readstb,A(5 downto 2));
			LoadSPIBitCount <= OneOfNDecode(SPIs,SPIBitCountSel,writestb,A(5 downto 2));
			ReadSPIBitCount <= OneOfNDecode(SPIs,SPIBitCountSel,Readstb,A(5 downto 2));
			LoadSPIBitRate <= OneOfNDecode(SPIs,SPIBitRateSel,writestb,A(5 downto 2));
			ReadSPIBitRate <= OneOfNDecode(SPIs,SPIBitRateSel,Readstb,A(5 downto 2));
		end process SPIDecodeProcess;

		DoSPIPins: process(SPIFrame,SPIOut,SPIClk)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = SPITag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB
						when SPIFramePin =>
							AltData(i) <= SPIFrame(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when SPIOutPin =>
							AltData(i) <= SPIOut(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when SPIClkPin =>
							AltData(i) <= SPIClk(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when SPIInPin =>		
							SPIIn(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when others => null;
					end case;
				end if;
			end loop;
		end process;		
	end generate;		
	
	makebspimod:  if BSPIs >0  generate		
	signal LoadBSPIData: std_logic_vector(BSPIs -1 downto 0);
	signal ReadBSPIData: std_logic_vector(BSPIs -1 downto 0);     
	signal LoadBSPIDescriptor: std_logic_vector(BSPIs -1 downto 0);
	signal ReadBSPIFIFOCOunt: std_logic_vector(BSPIs -1 downto 0);
	signal ClearBSPIFIFO: std_logic_vector(BSPIs -1 downto 0);
	signal BSPIClk: std_logic_vector(BSPIs -1 downto 0);
	signal BSPIIn: std_logic_vector(BSPIs -1 downto 0);
	signal BSPIOut: std_logic_vector(BSPIs -1 downto 0);
	signal BSPIFrame: std_logic_vector(BSPIs -1 downto 0);
	signal BSPIDataSel : std_logic;	
	signal BSPIFIFOCountSel : std_logic;
	signal BSPIDescriptorSel : std_logic;	
	type BSPICSType is array(BSPIs-1 downto 0) of std_logic_vector(BSPICSWidth-1 downto 0);
	signal BSPICS : BSPICSType;	
	begin
		makebspis: for i in 0 to BSPIs -1 generate
			bspi: entity work.BufferedSPI
			generic map (
				cswidth => BSPICSWidth,
				gatedcs => false)		
			port map (
				clk  => clklow,
				ibus => ibus,
				obus => obus,
				addr => A(5 downto 2),
				hostpush => LoadBSPIData(i),
				hostpop => ReadBSPIData(i),
				loaddesc => LoadBSPIDescriptor(i),
				loadasend => '0',
				clear => ClearBSPIFIFO(i),
				readcount => ReadBSPIFIFOCount(i),
				spiclk => BSPIClk(i),
				spiin => BSPIIn(i),
				spiout => BSPIOut(i),
				spiframe => BSPIFrame(i),
				spicsout => BSPICS(i)
				);
		end generate;	

		BSPIDecodeProcess : process (A,Readstb,writestb,BSPIDataSel,BSPIFIFOCountSel,BSPIDescriptorSel)
		begin		
			if A(15 downto 8) = BSPIDataAddr then	 --  BSPI data register select
				BSPIDataSel <= '1';
			else
				BSPIDataSel <= '0';
			end if;		
			if A(15 downto 8) = BSPIFIFOCountAddr then	 --  BSPI FIFO count register select
				BSPIFIFOCountSel <= '1';
			else
				BSPIFIFOCountSel <= '0';
			end if;
			if A(15 downto 8) = BSPIDescriptorAddr then	 --  BSPI channel descriptor register select
				BSPIDescriptorSel <= '1';
			else
				BSPIDescriptorSel <= '0';
			end if;
			LoadBSPIData <= OneOfNDecode(BSPIs,BSPIDataSel,writestb,A(7 downto 6)); -- 4 max
			ReadBSPIData <= OneOfNDecode(BSPIs,BSPIDataSel,Readstb,A(7 downto 6));
			LoadBSPIDescriptor<= OneOfNDecode(BSPIs,BSPIDescriptorSel,writestb,A(5 downto 2));
			ReadBSPIFIFOCOunt <= OneOfNDecode(BSPIs,BSPIFIFOCountSel,Readstb,A(5 downto 2));
			ClearBSPIFIFO <= OneOfNDecode(BSPIs,BSPIFIFOCountSel,writestb,A(5 downto 2));
		end process BSPIDecodeProcess;

		DoBSPIPins: process(BSPIFrame, BSPIOut, BSPIClk, BSPICS, IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = BSPITag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB
						when BSPIFramePin =>
							AltData(i) <= BSPIFrame(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BSPIOutPin =>
							AltData(i) <= BSPIOut(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BSPIClkPin =>
							AltData(i) <= BSPIClk(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BSPIInPin =>		
							BSPIIn(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when others => 
						   AltData(i) <= BSPICS(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(6 downto 0))-5);
						   -- magic foo, magic foo, what on earth does it do?						
						   -- (this needs to written more clearly!)							
					end case;
				end if;
			end loop;
		end process;		
	end generate;

	makedbspimod:  if DBSPIs >0  generate	
	signal LoadDBSPIData: std_logic_vector(DBSPIs -1 downto 0);
	signal ReadDBSPIData: std_logic_vector(DBSPIs -1 downto 0);     
	signal LoadDBSPIDescriptor: std_logic_vector(DBSPIs -1 downto 0);
	signal ReadDBSPIFIFOCOunt: std_logic_vector(DBSPIs -1 downto 0);
	signal ClearDBSPIFIFO: std_logic_vector(DBSPIs -1 downto 0);
	signal DBSPIClk: std_logic_vector(DBSPIs -1 downto 0);
	signal DBSPIIn: std_logic_vector(DBSPIs -1 downto 0);
	signal DBSPIOut: std_logic_vector(DBSPIs -1 downto 0);
	type DBSPICSType is array(DBSPIs-1 downto 0) of std_logic_vector(DBSPICSWidth-1 downto 0);
	signal DBSPICS : DBSPICSType;
	signal DBSPIDataSel : std_logic;	
	signal DBSPIFIFOCountSel : std_logic;
	signal DBSPIDescriptorSel : std_logic;
	begin
		makedbspis: for i in 0 to DBSPIs -1 generate
			bspi: entity work.BufferedSPI
			generic map (
				cswidth => DBSPICSWidth,
				gatedcs => true
				)		
			port map (
				clk  => clklow,
				ibus => ibus,
				obus => obus,
				addr => A(5 downto 2),
				hostpush => LoadDBSPIData(i),
				hostpop => ReadDBSPIData(i),
				loaddesc => LoadDBSPIDescriptor(i),
				loadasend => '0',
				clear => ClearDBSPIFIFO(i),
				readcount => ReadDBSPIFIFOCount(i),
				spiclk => DBSPIClk(i),
				spiin => DBSPIIn(i),
				spiout => DBSPIOut(i),
				spicsout => DBSPICS(i)
				);
		end generate;	
	
		DBSPIDecodeProcess : process (A,Readstb,writestb,DBSPIDataSel,DBSPIFIFOCountSel,DBSPIDescriptorSel)
		begin		
			if A(15 downto 8) = DBSPIDataAddr then	 --  DBSPI data register select
				DBSPIDataSel <= '1';
			else
				DBSPIDataSel <= '0';
			end if;
			if A(15 downto 8) = DBSPIFIFOCountAddr then	 --  DBSPI FIFO count register select
				DBSPIFIFOCountSel <= '1';
			else
				DBSPIFIFOCountSel <= '0';
			end if;
			if A(15 downto 8) = DBSPIDescriptorAddr then	 --  DBSPI channel descriptor register select
				DBSPIDescriptorSel <= '1';
			else
				DBSPIDescriptorSel <= '0';
			end if;
			LoadDBSPIData <= OneOfNDecode(DBSPIs,DBSPIDataSel,writestb,A(7 downto 6)); -- 4 max
			ReadDBSPIData <= OneOfNDecode(DBSPIs,DBSPIDataSel,Readstb,A(7 downto 6));
			LoadDBSPIDescriptor<= OneOfNDecode(DBSPIs,DBSPIDescriptorSel,writestb,A(5 downto 2));
			ReadDBSPIFIFOCOunt <= OneOfNDecode(DBSPIs,DBSPIFIFOCountSel,Readstb,A(5 downto 2));
			ClearDBSPIFIFO <= OneOfNDecode(DBSPIs,DBSPIFIFOCountSel,writestb,A(5 downto 2));
		end process DBSPIDecodeProcess;

		DoDBSPIPins: process(DBSPIOut, DBSPIClk, DBSPICS, IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = DBSPITag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB		
						when DBSPIOutPin =>
							AltData(i) <= DBSPIOut(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when DBSPIClkPin =>
							AltData(i) <= DBSPIClk(conv_integer(ThePinDesc(i)(23 downto 16)));											when DBSPIInPin =>		
							DBSPIIn(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when others => 
							AltData(i) <= DBSPICS(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(6 downto 0))-5);
				   		-- magic foo, magic foo, what on earth does it do?						
							-- (this needs to written more clearly!)							
					end case;
				end if;
			end loop;	
		end process;	
						
		DoLocalDDBSPIPins: process(LIOBits,DBSPICS,DBSPIClk,DBSPIOut) -- only for 4I69 LIO currently
		begin
			for i in 0 to LIOWidth -1 loop				-- loop through all the local I/O pins 
				report("Doing DBSPI LIOLoop: "& integer'image(i));
				if ThePinDesc(i+IOWidth)(15 downto 8) = DBSPITag then 	-- GTag (Local I/O starts at end of external I/O)				
					case (ThePinDesc(i+IOWidth)(7 downto 0)) is	--secondary pin function, drop MSB		
						when DBSPIOutPin =>
							LIOBits(i) <= DBSPIOut(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16)));				
							report("Local DBSPIOutPin found at LIOBit " & integer'image(i));
						when DBSPIClkPin =>
							LIOBits(i) <= DBSPIClk(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16)));				
							report("Local DBSPClkPin found at LIOBit " & integer'image(i));
						when DBSPIInPin =>		
							DBSPIIn(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16))) <= LIOBits(i);
							report("Local DBSPIInPin found at LIOBit " & integer'image(i));
						when others => 
							LIOBits(i) <= DBSPICS(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16)))(conv_integer(ThePinDesc(i+IOWidth)(6 downto 0))-5);			
							report("Local DBSPICSPin found at LIOBit " & integer'image(i));
						-- magic foo, magic foo, what on earth does it do?						
						-- (this needs to written more clearly!)							
					end case;
				end if;	
			end loop;		
		end process;	
	end generate;

	makesssimod:  if SSSIs >0  generate	
	signal LoadSSSIData0: std_logic_vector(SSSIs -1 downto 0);
	signal ReadSSSIData0: std_logic_vector(SSSIs -1 downto 0);     
	signal ReadSSSIData1: std_logic_vector(SSSIs -1 downto 0);     
	signal LoadSSSIControl: std_logic_vector(SSSIs -1 downto 0);
	signal ReadSSSIControl: std_logic_vector(SSSIs -1 downto 0);
	signal SSSIClk: std_logic_vector(SSSIs -1 downto 0);
	signal SSSIData: std_logic_vector(SSSIs -1 downto 0);
	signal SSSIBusyBits: std_logic_vector(SSSIs -1 downto 0);
	signal SSSIDAVBits: std_logic_vector(SSSIs -1 downto 0);
	signal SSSIDataSel0 : std_logic;	
	signal SSSIDataSel1 : std_logic;	
	signal SSSIControlSel : std_logic;
	signal GlobalPStartSSSI : std_logic;
	signal GlobalSSSIBusySel : std_logic;
	signal GlobalTStartSSSI : std_logic;
		begin
		makesssis: for i in 0 to SSSIs -1 generate
			sssi: entity work.SimpleSSI
			port  map ( 
				clk => clklow,
				ibus => ibus,
				obus => obus,
				loadcontrol => LoadSSSIControl(i),
				lstart => LoadSSSIData0(i),
				pstart => GlobalPstartSSSI,
				timers => RateSources,
				readdata0 => ReadSSSIData0(i),
				readdata1 => ReadSSSIData1(i),
				readcontrol => ReadSSSIControl(i),
				busyout => SSSIBusyBits(i),
				davout => SSSIDAVBits(i),
				ssiclk => SSSIClk(i),
				ssidata => SSSIData(i)
				);
		end generate;

		SSSIDecodeProcess : process (A,Readstb,writestb,SSSIDataSel0,GlobalSSSIBusySel, 
		                             SSSIBusyBits,SSSIDAvBits,SSSIDataSel1,SSSIControlSel)
		begin		
			if A(15 downto 8) = SSSIDataAddr0 then	 --  SSSI data register select 0
				SSSIDataSel0 <= '1';
			else
				SSSIDataSel0 <= '0';
			end if;
			if A(15 downto 8) = SSSIDataAddr1 then	 --  SSSI data register select 1
				SSSIDataSel1 <= '1';
			else
				SSSIDataSel1 <= '0';
			end if;
			
			if A(15 downto 8) = SSSIControlAddr then	 --  SSSI control register select
				SSSIControlSel <= '1';
			else
				SSSIControlSel <= '0';
			end if;			
			if A(15 downto 8) = SSSIGlobalPStartAddr and writestb = '1' then	 --  
				GlobalPStartSSSI <= '1';
			else
				GlobalPStartSSSI <= '0';
			end if;
			if A(15 downto 8) = SSSIGlobalPStartAddr and readstb = '1' then	 --  
				GlobalSSSIBusySel <= '1';
			else
				GlobalSSSIBusySel <= '0';
			end if;
			LoadSSSIData0 <= OneOfNDecode(SSSIs,SSSIDataSel0,writestb,A(7 downto 2)); -- 64 max
			ReadSSSIData0 <= OneOfNDecode(SSSIs,SSSIDataSel0,Readstb,A(7 downto 2));
			ReadSSSIData1 <= OneOfNDecode(SSSIs,SSSIDataSel1,Readstb,A(7 downto 2));
			LoadSSSIControl <= OneOfNDecode(SSSIs,SSSIControlSel,writestb,A(7 downto 2));
			ReadSSSIControl <= OneOfNDecode(SSSIs,SSSIControlSel,Readstb,A(7 downto 2));
			obus <= (others => 'Z');
			if GlobalSSSIBusySel = '1' then
				obus(SSSIs -1 downto 0) <= SSSIBusyBits;
				obus(31 downto SSSIs) <= (others => '0');
			end if;	
		end process SSSIDecodeProcess;

		DoSSIPins: process(SSSIClk, IOBits,SSSIDavBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = SSSITag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB
						when SSSIClkPin =>
							AltData(i) <= SSSIClk(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when SSSIClkEnPin =>
							AltData(i) <= '0';		-- for RS-422 daughtercards that have drive enables				
						when SSSIDAVPin =>
							AltData(i) <= SSSIDAVBits(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when SSSIDataPin =>		
							SSSIData(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when others => null;
					end case;
				end if;
			end loop;	
		end process;	
	end generate;

	makeFAbsmod:  if FAbss >0  generate	
	signal LoadFAbsData0: std_logic_vector(FAbss -1 downto 0);
	signal ReadFAbsData0: std_logic_vector(FAbss -1 downto 0);     
	signal ReadFAbsData1: std_logic_vector(FAbss -1 downto 0);     
	signal ReadFAbsData2: std_logic_vector(FAbss -1 downto 0);     
	signal LoadFAbsControl0: std_logic_vector(FAbss -1 downto 0);
	signal LoadFAbsControl1: std_logic_vector(FAbss -1 downto 0);
	signal ReadFAbsControl0: std_logic_vector(FAbss -1 downto 0);
	signal ReadFAbsControl1: std_logic_vector(FAbss -1 downto 0);
	signal LoadFAbsControl2: std_logic_vector(FAbss -1 downto 0);
	signal FAbsBusyBits: std_logic_vector(FAbss -1 downto 0);
	signal FAbsDAVBits: std_logic_vector(FAbss -1 downto 0);
	signal FAbsRequest: std_logic_vector(FAbss -1 downto 0);
	signal FAbsData: std_logic_vector(FAbss -1 downto 0);
	signal FAbsTestClk: std_logic_vector(FAbss -1 downto 0);
--- FanucAbs interface related signals
	signal FAbsDataSel0 : std_logic;	
	signal FAbsDataSel1 : std_logic;	
	signal FAbsDataSel2 : std_logic;	
	signal FAbsControlSel0 : std_logic;
	signal FAbsControlSel1 : std_logic;
	signal FAbsControlSel2 : std_logic;
	signal GlobalPStartFAbs : std_logic;
	signal GlobalFAbsBusySel : std_logic;

	begin
		makeFAbss: for i in 0 to FAbss -1 generate
			FAbs: entity work.FanucAbs
			generic map (
				Clock => ClockLow
				)
			port  map ( 
				clk => clklow,
				ibus => ibus,
				obus => obus,
				loadcontrol0 => LoadFAbsControl0(i),
				loadcontrol1 => LoadFAbsControl1(i),
				loadcontrol2 => LoadFAbsControl2(i),
				lstart => LoadFabsData0(i),
				pstart => GlobalPstartFAbs,
				timers => RateSources,
				readdata0 => ReadFAbsData0(i),
				readdata1 => ReadFAbsData1(i),
				readdata2 => ReadFAbsData2(i),
				readcontrol0 => ReadFAbsControl0(i),
				readcontrol1 => ReadFAbsControl1(i),
				busyout => FabsBusyBits(i),
				davout => FabsDAVBits(i),
				requestout => FAbsRequest(i),
				rxdata => FAbsData(i),
				testclk => FAbsTestClk(i)
				);
		end generate;

		FAbsDecodeProcess : process (A,Readstb,writestb,FAbsDataSel0,FAbsDataSel1,FAbsDataSel2,
												FAbsControlSel0,FAbsControlSel1,FAbsControlSel2,
												GlobalFabsBusySel,FAbsBusyBits)
		begin		
			if A(15 downto 8) = FAbsDataAddr0 then	 --  FAbs data register select
				FAbsDataSel0 <= '1';
			else
				FAbsDataSel0 <= '0';
			end if;
			if A(15 downto 8) = FAbsDataAddr1 then	 --  FAbs data register select
				FAbsDataSel1 <= '1';
			else
				FAbsDataSel1 <= '0';
			end if;
			if A(15 downto 8) = FAbsDataAddr2 then	 --  FAbs data register select
				FAbsDataSel2 <= '1';
			else
				FAbsDataSel2 <= '0';
			end if;
			if A(15 downto 8) = FAbsControlAddr0 then	 --  FAbs control register 0 select
				FAbsControlSel0 <= '1';
			else
				FAbsControlSel0 <= '0';
			end if;
			if A(15 downto 8) = FAbsControlAddr1 then	 --  FAbs control register 1 select
				FAbsControlSel1 <= '1';
			else
				FAbsControlSel1 <= '0';
			end if;
			if A(15 downto 8) = FAbsDataAddr2 then	 	--  FAbs control register 2 select
				FAbsControlSel2 <= '1';
			else
				FAbsControlSel2 <= '0';
			end if;
			if A(15 downto 8) = FAbsGlobalPStartAddr and writestb = '1' then	 --  
				GlobalPStartFAbs <= '1';
			else
				GlobalPStartFAbs <= '0';
			end if;
			if A(15 downto 8) = FAbsGlobalPStartAddr and readstb = '1' then	 --  
				GlobalFAbsBusySel <= '1';
			else
				GlobalFAbsBusySel <= '0';
			end if;
			LoadFAbsData0 <= OneOfNDecode(FAbss,FAbsDataSel0,writestb,A(7 downto 2)); -- 64 max
			ReadFAbsData0 <= OneOfNDecode(FAbss,FAbsDataSel0,Readstb,A(7 downto 2));
			ReadFAbsData1 <= OneOfNDecode(FAbss,FAbsDataSel1,Readstb,A(7 downto 2));
			ReadFAbsData2 <= OneOfNDecode(FAbss,FAbsDataSel2,Readstb,A(7 downto 2));
			LoadFAbsControl0 <= OneOfNDecode(FAbss,FAbsControlSel0,writestb,A(7 downto 2));
			LoadFAbsControl1 <= OneOfNDecode(FAbss,FAbsControlSel1,writestb,A(7 downto 2));
			LoadFAbsControl2 <= OneOfNDecode(FAbss,FAbsControlSel2,writestb,A(7 downto 2));
			ReadFAbsControl0 <= OneOfNDecode(FAbss,FAbsControlSel0,Readstb,A(7 downto 2));
			ReadFAbsControl1 <= OneOfNDecode(FAbss,FAbsControlSel1,Readstb,A(7 downto 2));
			obus <= (others => 'Z');
			if GlobalFabsBusySel = '1' then
				obus(FAbss -1 downto 0) <= FAbsBusyBits;
				obus(31 downto FAbss) <= (others => '0');
			end if;	
		end process FAbsDecodeProcess;

		DoFAbsPins: process(FAbsRequest,FAbsTestClk,IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = FAbsTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB
						when FAbsRQPin =>
							AltData(i) <= FAbsRequest(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when FAbsRQEnPin =>
							AltData(i) <= '0';		-- for RS-422 daughtercards that have drive enables				
						when FAbsTestClkPin =>
							AltData(i) <= FAbsTestClk(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when FAbsDAVPin =>
							AltData(i) <= FAbsDAVBits(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when FAbsDataPin =>		
							FAbsData(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when others => null;
					end case;
				end if;
			end loop;	
		end process;	
	end generate;

	makebissmod:  if BISSs >0  generate	
	signal LoadBISSData: std_logic_vector(BISSs -1 downto 0);
	signal ReadBISSData: std_logic_vector(BISSs -1 downto 0);     
	signal LoadBISSControl0: std_logic_vector(BISSs -1 downto 0);
	signal LoadBISSControl1: std_logic_vector(BISSs -1 downto 0);
	signal ReadBISSControl0: std_logic_vector(BISSs -1 downto 0);
	signal ReadBISSControl1: std_logic_vector(BISSs -1 downto 0);
	signal BISSClk: std_logic_vector(BISSs -1 downto 0);
	signal BISSData: std_logic_vector(BISSs -1 downto 0);	
	signal BISSTestData: std_logic_vector(BISSs -1 downto 0);		-- debug signal
	signal BISSSampleTime: std_logic_vector(BISSs -1 downto 0);		-- debug signal
--- BISS interface related signals
	signal BISSDataSel : std_logic;	
	signal BISSControlSel0 : std_logic;
	signal BISSControlSel1 : std_logic;
	signal GlobalPStartBISS : std_logic;
	signal BISSBusyBits: std_logic_vector(BISSs -1 downto 0);
	signal BISSDAVBits: std_logic_vector(BISSs -1 downto 0);
	signal GlobalBISSBusySel : std_logic;
	
	
	begin
		makebisss: for i in 0 to BISSs -1 generate
			BISS: entity work.biss
			port  map ( 
				clk => clklow,
				hclk => clkhigh,			
				ibus => ibus,
				obus => obus,
				poplifo => ReadBISSData(i),
				lstart => LoadBISSData(i),
				pstart => GlobalPstartBISS,
				timers => RateSources,
				loadcontrol0 => LoadBISSControl0(i),
				loadcontrol1 => LoadBISSControl1(i),
				readcontrol0 => ReadBISSControl0(i),
				readcontrol1 => ReadBISSControl1(i),
				busyout => BISSBusyBits(i),
				davout => BISSDAVBits(i),
--				testdata => BISSTestData(i),
--				sampletime => BISSSampleTime(i),
				bissclk => BISSClk(i),
				bissdata => BISSData(i)
				);
		end generate;
		
		BISSDecodeProcess : process (A,Readstb,writestb,BISSControlSel0,BISSControlSel1,
											  BISSDataSel,GlobalBISSBusySel,BISSBusyBits)
		begin		
			if A(15 downto 8) = BISSDataAddr then	 --  BISS data register select
				BISSDataSel <= '1';
			else
				BISSDataSel <= '0';
			end if;
			if A(15 downto 8) = BISSControlAddr0 then	 --  BISS control register select
				BISSControlSel0 <= '1';
			else
				BISSControlSel0 <= '0';
			end if;
			if A(15 downto 8) = BISSControlAddr1 then	 --  BISS control register select
				BISSControlSel1 <= '1';
			else
				BISSControlSel1 <= '0';
			end if;
			if A(15 downto 8) = BISSGlobalPStartAddr and writestb = '1' then	 --  
				GlobalPStartBISS <= '1';
			else
				GlobalPStartBISS <= '0';
			end if;
			if A(15 downto 8) = BISSGlobalPStartAddr and readstb = '1' then	 --  
				GlobalBISSBusySel <= '1';
			else
				GlobalBISSBusySel <= '0';
			end if;

			obus <= (others => 'Z');			
			if GlobalBISSBusySel = '1' then
				obus(BISSs -1 downto 0) <= BISSBusyBits;
				obus(31 downto BISSs) <= (others => '0');
			end if;	
			
			LoadBISSData <= OneOfNDecode(BISSs,BISSDataSel,writestb,A(5 downto 2)); 
			ReadBISSData <= OneOfNDecode(BISSs,BISSDataSel,Readstb,A(5 downto 2));
			LoadBISSControl0 <= OneOfNDecode(BISSs,BISSControlSel0,writestb,A(5 downto 2));
			LoadBISSControl1 <= OneOfNDecode(BISSs,BISSControlSel1,writestb,A(5 downto 2));
			ReadBISSControl0 <= OneOfNDecode(BISSs,BISSControlSel0,Readstb,A(5 downto 2));
			ReadBISSControl1 <= OneOfNDecode(BISSs,BISSControlSel1,Readstb,A(5 downto 2));
		end process BISSDecodeProcess;

		DoBISSPins: process(BISSClk, IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = BISSTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB
						when BISSClkPin =>
							AltData(i) <= BISSClk(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BISSTestDataPin =>
							AltData(i) <= BISSTestData(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BISSSampleTimePin =>
							AltData(i) <= BISSSampleTime(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BISSClkEnPin =>
							AltData(i) <= '0';			-- for RS-422 daughtercards that have drive enables				
						when BISSDAVPin =>
							AltData(i) <= BISSDAVBits(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when BISSDataPin =>		
							BISSData(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
						when others => null;
					end case;
				end if;
			end loop;	
		end process;
	end generate;

	makedaqfifomod:  if DAQFIFOs >0  generate	
	signal ReadDAQFIFO: std_logic_vector(DAQFIFOs-1 downto 0);
	signal ReadDAQFIFOCount: std_logic_vector(DAQFIFOs-1 downto 0);
	signal ClearDAQFIFO: std_logic_vector(DAQFIFOs-1 downto 0);
	signal LoadDAQFIFOMode: std_logic_vector(DAQFIFOs-1 downto 0);
	signal ReadDAQFIFOMode: std_logic_vector(DAQFIFOs-1 downto 0);
	signal PushDAQFIFOFrac: std_logic_vector(DAQFIFOs-1 downto 0);
	type DAQFIFODataType is array(DAQFIFOs-1 downto 0) of std_logic_vector(DAQFIFOWidth-1 downto 0);
	signal DAQFIFOData: DAQFIFODataType;
	signal DAQFIFOFull: std_logic_vector(DAQFIFOs-1 downto 0);
	signal DAQFIFOStrobe: std_logic_vector(DAQFIFOs-1 downto 0);	
	signal DAQFIFODataSel : std_logic;
	signal DAQFIFOCountSel : std_logic;
	signal DAQFIFOModeSel : std_logic;
	signal DAQFIFOReq: std_logic_vector(DAQFIFOs-1 downto 0);
	begin
		DRQSources <= DAQFIFOReq;			-- this will grow as other demand mode DMA sources are added
		makedaqfifos: for i in 0 to DAQFIFOs -1 generate
			adaqfifo: entity work.DAQFIFO16				-- need to parametize width
			generic map (
				depth => 2048									-- this needs to be in module header
				)
			port  map ( 
				clk => clklow,
				ibus => ibus,
				obus => obus,
				readfifo => ReadDAQFIFO(i),
				readfifocount => ReadDAQFIFOCount(i),
				clearfifo =>  ClearDAQFIFO(i),
				loadmode =>  LoadDAQFIFOMode(i),
				readmode =>  ReadDAQFIFOMode(i) ,
				pushfrac =>  PushDAQFIFOFrac(i),
				daqdata =>   DAQFIFOData(i),
				daqfull =>   DAQFIFOFull(i),
				daqreq => 	 DAQFIFOReq(i),
				daqstrobe => DAQFIFOStrobe(i)
				);
		end generate;
		
		DAQFIFODecodeProcess : process (A,Readstb,writestb,DAQFIFODataSel,DAQFIFOCountSel,DAQFIFOModeSel)
		begin		
			if A(15 downto 8) = DAQFIFODataAddr then
				DAQFIFODataSel <= '1';
			else	
				DAQFIFODataSel <= '0';
			end if;
			if A(15 downto 8) = DAQFIFOCountAddr then
				DAQFIFOCountSel <= '1';      
			else	
				DAQFIFOCountSel <= '0';      
			end if;
			if A(15 downto 8) = DAQFIFOModeAddr then
				DAQFIFOModeSel <= '1';      
			else	
				DAQFIFOModeSel <= '0';      
			end if;
			ReadDAQFIFO <= OneOfNDecode(DAQFIFOs,DAQFIFODataSel,Readstb,A(7 downto 6));	-- 16 addresses per fifo to allow burst reads	 
			PushDAQFIFOFrac <= OneOfNDecode(DAQFIFOs,DAQFIFODataSel,writestb,A(5 downto 2)); 
			ReadDAQFIFOCount <= OneOfNDecode(DAQFIFOs,DAQFIFOCountSel,Readstb,A(5 downto 2)); 
			ClearDAQFIFO <= OneOfNDecode(DAQFIFOs,DAQFIFOCountSel,writestb,A(5 downto 2)); 
			ReadDAQFIFOMode <= OneOfNDecode(DAQFIFOs,DAQFIFOModeSel,Readstb,A(5 downto 2)); 
			LoadDAQFIFOMode <= OneOfNDecode(DAQFIFOs,DAQFIFOModeSel,writestb,A(5 downto 2)); 
		end process DAQFIFODecodeProcess;

		DoDAQFIFOPins: process(DAQFIFOFull, IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = DAQFIFOTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					if (ThePinDesc(i)(7 downto 0) and x"C0") = x"00" then 	-- DAQ data matches 0X .. 3X
						DAQFIFOData(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(5 downto 0))-1) <= IOBits(i);		-- 16 max ports			
					end if;
					if ThePinDesc(i)(7 downto 0) = DAQFIFOStrobePin then 	
						 DAQFIFOStrobe(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
					end if;			
					if ThePinDesc(i)(7 downto 0) = DAQFIFOFullPin then 	
						AltData(i) <= DAQFIFOFull(conv_integer(ThePinDesc(i)(23 downto 16)));					
					end if;
				end if;
			end loop;	
		end process;

	end generate;

-------------------------------------Standard UART---------------------------------------------------------
---------------------------------------------------------------------------------------------------------

	makeuartrmod:  if UARTs >0  generate		
	signal LoadUARTRData: std_logic_vector(UARTs -1 downto 0);
	signal LoadUARTRBitRate: std_logic_vector(UARTs -1 downto 0);
	signal ReadUARTRBitrate: std_logic_vector(UARTs -1 downto 0);
	signal ClearUARTRFIFO: std_logic_vector(UARTs -1 downto 0);
	signal ReadUARTRFIFOCount: std_logic_vector(UARTs -1 downto 0);
	signal ReadUARTRModeReg: std_logic_vector(UARTs -1 downto 0);
	signal LoadUARTRModeReg: std_logic_vector(UARTs -1 downto 0);
	signal UARTRFIFOHasData: std_logic_vector(UARTs -1 downto 0);
	signal URData: std_logic_vector(UARTs -1 downto 0);	
	signal LoadUARTTData: std_logic_vector(UARTs -1 downto 0);
	signal LoadUARTTBitRate: std_logic_vector(UARTs -1 downto 0);
	signal LoadUARTTModeReg: std_logic_vector(UARTs -1 downto 0);	
	signal CLearUARTTFIFO: std_logic_vector(UARTs -1 downto 0);
	signal ReadUARTTFIFOCount: std_logic_vector(UARTs -1 downto 0);
	signal ReadUARTTBitrate: std_logic_vector(UARTs -1 downto 0);
	signal ReadUARTTModeReg: std_logic_vector(UARTs -1 downto 0);
	signal UARTTFIFOEmpty: std_logic_vector(UARTs -1 downto 0);
	signal UTDrvEn: std_logic_vector(UARTs -1 downto 0);
	signal UTData: std_logic_vector(UARTs -1 downto 0);		
	signal UARTTDataSel : std_logic;
	signal UARTTBitrateSel : std_logic;
	signal UARTTFIFOCountSel : std_logic;
	signal UARTTModeRegSel : std_logic; 
	signal UARTRDataSel : std_logic;
	signal UARTRBitrateSel : std_logic;
	signal UARTRFIFOCountSel : std_logic;
	signal UARTRModeRegSel : std_logic;
	
	begin		
		makeuartrs: for i in 0 to UARTs -1 generate
			auarrx: entity work.uartr	
			port map (
				clk => clklow,
				ibus => ibus,
				obus => obus,
				addr => A(3 downto 2),
				popfifo => LoadUARTRData(i),
				loadbitrate => LoadUARTRBitRate(i),
				readbitrate => ReadUARTRBitrate(i),
				clrfifo => ClearUARTRFIFO(i),
				readfifocount => ReadUARTRFIFOCount(i),
				loadmode => LoadUARTRModeReg(i),
				readmode => ReadUARTRModeReg(i),
				fifohasdata => UARTRFIFOHasData(i),
				rxmask => UTDrvEn(i),			-- for half duplex rx mask
				rxdata => URData(i)
				);
		end generate;
		
		UARTRDecodeProcess : process (A,Readstb,writestb,UARTRDataSel,UARTRBitRateSel,UARTRFIFOCountSel,UARTRModeRegSel)
		begin		
			if A(15 downto 8) = UARTRDataAddr then	 --  UART RX data register select
				UARTRDataSel <= '1';
			else
				UARTRDataSel <= '0';
			end if;
			if A(15 downto 8) = UARTRFIFOCountAddr then	 --  UART RX FIFO count register select
				UARTRFIFOCountSel <= '1';
			else
				UARTRFIFOCountSel <= '0';
			end if;
			if A(15 downto 8) = UARTRBitrateAddr then	 --  UART RX bit rate register select
				UARTRBitrateSel <= '1';
			else
				UARTRBitrateSel <= '0';
			end if;
			if A(15 downto 8) = UARTRModeRegAddr then	 --  UART RX status register select
				UARTRModeRegSel <= '1';
			else
				UARTRModeRegSel <= '0';
			end if;			LoadUARTRData <= OneOfNDecode(UARTs,UARTRDataSel,Readstb,A(7 downto 4));
			LoadUARTRBitRate <= OneOfNDecode(UARTs,UARTRBitRateSel,writestb,A(7 downto 4));
			ReadUARTRBitrate <= OneOfNDecode(UARTs,UARTRBitRateSel,Readstb,A(7 downto 4));
			ClearUARTRFIFO <= OneOfNDecode(UARTs,UARTRFIFOCountSel,writestb,A(7 downto 4));
			ReadUARTRFIFOCount <= OneOfNDecode(UARTs,UARTRFIFOCountSel,Readstb,A(7 downto 4));
			LoadUARTRModeReg <= OneOfNDecode(UARTs,UARTRModeRegSel,writestb,A(7 downto 4));
			ReadUARTRModeReg <= OneOfNDecode(UARTs,UARTRModeRegSel,Readstb,A(7 downto 4));
		end process UARTRDecodeProcess;

		DoUARTRPins: process(IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = UARTRTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					if (ThePinDesc(i)(7 downto 0)) = URDataPin then
						URData(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
					end if;
				end if;
			end loop;	
		end process;

		DoLocalUARTRPins: process(LIOBits) -- only for 4I90 LIO currently
		begin
			for i in 0 to LIOWidth -1 loop				-- loop through all the local I/O pins 
				report("Doing UARTR LIOLoop: "& integer'image(i));
				if ThePinDesc(i+IOWidth)(15 downto 8) = UARTRTag then 	-- GTag (Local I/O starts at end of external I/O)				
					if (ThePinDesc(i+IOWidth)(7 downto 0)) = URDataPin then
						URData(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16))) <= LIOBits(i);
						report("Local URDataPin found at LIOBit " & integer'image(i));
					end if;
				end if;	
			end loop;		
		end process;	
		
		makeuarttxs: for i in 0 to UARTs -1 generate
			auartx:  entity work.uartx	
			port map (
				clk => clklow,
				ibus => ibus,
				obus => obus,
				addr => A(3 downto 2),
				pushfifo => LoadUARTTData(i),
				loadbitrate => LoadUARTTBitRate(i),
				readbitrate => ReadUARTTBitrate(i),
				clrfifo => ClearUARTTFIFO(i),
				readfifocount => ReadUARTTFIFOCount(i),
				loadmode => LoadUARTTModeReg(i),
				readmode => ReadUARTTModeReg(i),
				fifoempty => UARTTFIFOEmpty(i),
				txen => '1',
				drven => UTDrvEn(i),
				txdata => UTData(i)
				);
		end generate;	

		UARTTDecodeProcess : process (A,Readstb,writestb,UARTTDataSel,UARTTBitRateSel,UARTTModeRegSel,UARTTFIFOCountSel)
		begin		
			if A(15 downto 8) = UARTTDataAddr then	 --  UART TX data register select
				UARTTDataSel <= '1';
			else
				UARTTDataSel <= '0';
			end if;
			if A(15 downto 8) = UARTTFIFOCountAddr then	 --  UART TX FIFO count register select
				UARTTFIFOCountSel <= '1';
			else
				UARTTFIFOCountSel <= '0';
			end if;
			if A(15 downto 8) = UARTTBitrateAddr then	 --  UART TX bit rate register select
				UARTTBitrateSel <= '1';
			else
				UARTTBitrateSel <= '0';
			end if;
			if A(15 downto 8) = UARTTModeRegAddr then	 --  UART TX bit mode register select
				UARTTModeRegSel <= '1';
			else
				UARTTModeRegSel <= '0';
			end if;
			LoadUARTTData <= OneOfNDecode(UARTs,UARTTDataSel,writestb,A(7 downto 4));
			LoadUARTTBitRate <= OneOfNDecode(UARTs,UARTTBitRateSel,writestb,A(7 downto 4));
			ReadUARTTBitrate <= OneOfNDecode(UARTs,UARTTBitRateSel,Readstb,A(7 downto 4));
			LoadUARTTModeReg <= OneOfNDecode(UARTs,UARTTModeRegSel,writestb,A(7 downto 4));
				ReadUARTTModeReg <= OneOfNDecode(UARTs,UARTTModeRegSel,Readstb,A(7 downto 4));
			ClearUARTTFIFO <= OneOfNDecode(UARTs,UARTTFIFOCountSel,writestb,A(7 downto 4));
			ReadUARTTFIFOCount <= OneOfNDecode(UARTs,UARTTFIFOCountSel,Readstb,A(7 downto 4));
		end process UARTTDecodeProcess;

		DoUARTTPins: process(UTData, UTDrvEn)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = UARTTTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when UTDataPin =>
							AltData(i) <= UTData(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when UTDrvEnPin =>
							AltData(i) <=  not UTDrvEn(conv_integer(ThePinDesc(i)(23 downto 16))); -- ExtIO is active low enable
						when others => null;								
					end case;
				end if;
			end loop;	
		end process;
		
		DoLocalUARTTPins: process(UTData, UTDrvEn)
		begin	
			for i in 0 to LIOWidth -1 loop				-- loop through all the local I/O pins 
				report("Doing UARTT LIOLoop: "& integer'image(i));
				if ThePinDesc(IOWidth+i)(15 downto 8) = UARTTTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(IOWidth+i)(7 downto 0)) is	--secondary pin function
						when UTDataPin =>
							LIOBits(i) <= UTData(conv_integer(ThePinDesc(IOWidth+i)(23 downto 16)));
							report("Local UTDataPin found at LIOBit " & integer'image(i));	
						when UTDrvEnPin =>
							LIOBits(i) <= UTDrvEn(conv_integer(ThePinDesc(IOWidth+i)(23 downto 16))); --LIO is active high enable	
							report("Local UTDrvEnPin found at LIOBit " & integer'image(i));
						when others => null;								
					end case;
				end if;
			end loop;	
		end process;
												
	end generate;

-------------------------------------Packet UART---------------------------------------------------------
---------------------------------------------------------------------------------------------------------

	makepktuartrmod:  if PktUARTs >0  generate		
	signal ReadPktUARTRData: std_logic_vector(PktUARTs -1 downto 0);
	signal LoadPktUARTRBitRate: std_logic_vector(PktUARTs -1 downto 0);
	signal ReadPktUARTRBitrate: std_logic_vector(PktUARTs -1 downto 0);
	signal ReadPktUARTRFrameCount: std_logic_vector(PktUARTs -1 downto 0);
	signal ReadPktUARTRModeReg: std_logic_vector(PktUARTs -1 downto 0);
	signal LoadPktUARTRModeReg: std_logic_vector(PktUARTs -1 downto 0);
	signal PktURData: std_logic_vector(PktUARTs -1 downto 0);	
	signal LoadPktUARTTData: std_logic_vector(PktUARTs -1 downto 0);
	signal LoadPktUARTTFrameCount: std_logic_vector(PktUARTs -1 downto 0);
	signal ReadPktUARTTFrameCount: std_logic_vector(PktUARTs -1 downto 0);
	signal LoadPktUARTTBitRate: std_logic_vector(PktUARTs -1 downto 0);
	signal ReadPktUARTTBitrate: std_logic_vector(PktUARTs -1 downto 0);
	signal LoadPktUARTTModeReg: std_logic_vector(PktUARTs -1 downto 0);	
	signal ReadPktUARTTModeReg: std_logic_vector(PktUARTs -1 downto 0);
	signal PktUTDrvEn: std_logic_vector(PktUARTs -1 downto 0);
	signal PktUTData: std_logic_vector(PktUARTs -1 downto 0);		
	signal PktUARTTDataSel : std_logic;
	signal PktUARTTBitrateSel : std_logic;
	signal PktUARTTFrameCountSel : std_logic;
	signal PktUARTTModeRegSel : std_logic; 
	signal PktUARTRDataSel : std_logic;
	signal PktUARTRBitrateSel : std_logic;
	signal PktUARTRFrameCountSel : std_logic;
	signal PktUARTRModeRegSel : std_logic;
	
	begin		
		makepktuartrs: for i in 0 to PktUARTs -1 generate
			pktauarrx: entity work.pktuartr	
			generic map (
				MaxFrameSize => 1024 )
			port map (
				clk => clklow,
				ibus => ibus,
				obus => obus,
				popdata => ReadPktUARTRData(i),
				poprc => ReadPktUARTRFrameCount(i),
				loadbitrate => LoadPktUARTRBitRate(i),
				readbitrate => ReadPktUARTRBitrate(i),
				loadmode => LoadPktUARTRModeReg(i),
				readmode => ReadPktUARTRModeReg(i),
				rxmask => PktUTDrvEn(i),			-- for half duplex rx mask
				rxdata => PktURData(i)
				);
		end generate;
		
		PktUARTRDecodeProcess : process (A,Readstb,writestb,PktUARTRDataSel,PktUARTRBitRateSel,
		                                 PktUARTRFrameCountSel,PktUARTRModeRegSel)
		begin		
			if A(15 downto 8) = PktUARTRDataAddr then	 --  PktUART RX data register select
				PktUARTRDataSel <= '1';
			else
				PktUARTRDataSel <= '0';
			end if;
			if A(15 downto 8) = PktUARTRFrameCountAddr then	 --  PktUART RX FIFO count register select
				PktUARTRFrameCountSel <= '1';
			else
				PktUARTRFrameCountSel <= '0';
			end if;
			if A(15 downto 8) = PktUARTRBitrateAddr then	 --  PktUART RX bit rate register select
				PktUARTRBitrateSel <= '1';
			else
				PktUARTRBitrateSel <= '0';
			end if;
			if A(15 downto 8) = PktUARTRModeRegAddr then	 --  PktUART RX status register select
				PktUARTRModeRegSel <= '1';
			else
				PktUARTRModeRegSel <= '0';
			end if;			
			
			ReadPktUARTRData <= OneOfNDecode(PktUARTs,PktUARTRDataSel,Readstb,A(5 downto 2));
			LoadPktUARTRBitRate <= OneOfNDecode(PktUARTs,PktUARTRBitRateSel,writestb,A(5 downto 2));
			ReadPktUARTRBitrate <= OneOfNDecode(PktUARTs,PktUARTRBitRateSel,Readstb,A(5 downto 2));
			ReadPktUARTRFrameCount <= OneOfNDecode(PktUARTs,PktUARTRFrameCountSel,Readstb,A(5 downto 2));
			LoadPktUARTRModeReg <= OneOfNDecode(PktUARTs,PktUARTRModeRegSel,writestb,A(5 downto 2));
			ReadPktUARTRModeReg <= OneOfNDecode(PktUARTs,PktUARTRModeRegSel,Readstb,A(5 downto 2));
		
		end process PktUARTRDecodeProcess;

		DoPktUARTRPins: process(IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = PktUARTRTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					if (ThePinDesc(i)(7 downto 0)) = PktURDataPin then
						PktURData(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
					end if;
				end if;
			end loop;	
		end process;

		DoLocalPktUARTRPins: process(LIOBits) -- only for 4I90 LIO currently
		begin
			for i in 0 to LIOWidth -1 loop				-- loop through all the local I/O pins 
				report("Doing PktUARTR LIOLoop: "& integer'image(i));
				if ThePinDesc(i+IOWidth)(15 downto 8) = PktUARTRTag then 	-- GTag (Local I/O starts at end of external I/O)				
					if (ThePinDesc(i+IOWidth)(7 downto 0)) = PktURDataPin then
						PktURData(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16))) <= LIOBits(i);
						report("Local PktURDataPin found at LIOBit " & integer'image(i));
					end if;
				end if;	
			end loop;		
		end process;	
		
		makepktuarttxs: for i in 0 to PktUARTs -1 generate
			apktuartx:  entity work.pktuartx	
			generic map (
				MaxFrameSize => 1024 )
			port map (
				clk => clklow,
				ibus => ibus,
				obus => obus,
				pushdata => LoadPktUARTTData(i),
				pushsc	=> LoadPktUARTTFrameCount(i),
				readsc   => ReadPktUARTTFrameCount(i),
				loadbitrate => LoadPktUARTTBitRate(i),
				readbitrate => ReadPktUARTTBitrate(i),
				loadmode => LoadPktUARTTModeReg(i),
				readmode => ReadPktUARTTModeReg(i),
				drven => PktUTDrvEn(i),
				txdata => PktUTData(i)
				);
		end generate;	

		PktUARTTDecodeProcess : process (A,Readstb,writestb,PktUARTTDataSel,PktUARTTBitRateSel,
													PktUARTTModeRegSel,PktUARTTFrameCountSel)
		begin		
			if A(15 downto 8) = PktUARTTDataAddr then	 --  PktUART TX data register select
				PktUARTTDataSel <= '1';
			else
				PktUARTTDataSel <= '0';
			end if;
			if A(15 downto 8) = PktUARTTFrameCountAddr then	 --  PktUART TX FIFO count register select
				PktUARTTFrameCountSel <= '1';
			else
				PktUARTTFrameCountSel <= '0';
			end if;
			if A(15 downto 8) = PktUARTTBitrateAddr then	 --  PktUART TX bit rate register select
				PktUARTTBitrateSel <= '1';
			else
				PktUARTTBitrateSel <= '0';
			end if;
			if A(15 downto 8) = PktUARTTModeRegAddr then	 --  PktUART TX bit mode register select
				PktUARTTModeRegSel <= '1';
			else
				PktUARTTModeRegSel <= '0';
			end if;
			LoadPktUARTTData <= OneOfNDecode(PktUARTs,PktUARTTDataSel,writestb,A(5 downto 2));
			LoadPktUARTTFrameCount <= OneOfNDecode(PktUARTs,PktUARTTFrameCountSel,writestb,A(5 downto 2));
			ReadPktUARTTFrameCount <= OneOfNDecode(PktUARTs,PktUARTTFrameCountSel,readstb,A(5 downto 2));
			LoadPktUARTTBitRate <= OneOfNDecode(PktUARTs,PktUARTTBitRateSel,writestb,A(5 downto 2));
			ReadPktUARTTBitrate <= OneOfNDecode(PktUARTs,PktUARTTBitRateSel,Readstb,A(5 downto 2));
			LoadPktUARTTModeReg <= OneOfNDecode(PktUARTs,PktUARTTModeRegSel,writestb,A(5 downto 2));
			ReadPktUARTTModeReg <= OneOfNDecode(PktUARTs,PktUARTTModeRegSel,Readstb,A(5 downto 2));
		end process PktUARTTDecodeProcess;

		DoPktUARTTPins: process(PktUTData, PktUTDrvEn)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = PktUARTTTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when PktUTDataPin =>
							AltData(i) <= PktUTData(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when UTDrvEnPin =>
							AltData(i) <=  not PktUTDrvEn(conv_integer(ThePinDesc(i)(23 downto 16))); -- ExtIO is active low enable
						when others => null;								
					end case;
				end if;
			end loop;	
		end process;
		
		DoLocalPktUARTTPins: process(PktUTData, PktUTDrvEn)
		begin	
			for i in 0 to LIOWidth -1 loop				-- loop through all the local I/O pins 
				report("Doing PktUARTT LIOLoop: "& integer'image(i));
				if ThePinDesc(IOWidth+i)(15 downto 8) = PktUARTTTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(IOWidth+i)(7 downto 0)) is	--secondary pin function
						when PktUTDataPin =>
							LIOBits(i) <= PktUTData(conv_integer(ThePinDesc(IOWidth+i)(23 downto 16)));
							report("Local PktUTDataPin found at LIOBit " & integer'image(i));	
						when UTDrvEnPin =>
							LIOBits(i) <= PktUTDrvEn(conv_integer(ThePinDesc(IOWidth+i)(23 downto 16))); --LIO is active high enable	
							report("Local PktUTDrvEnPin found at LIOBit " & integer'image(i));
						when others => null;								
					end case;
				end if;
			end loop;	
		end process;
												
	end generate;

	makebinoscmod:  if BinOscs >0  generate	
	signal LoadBinOscEna: std_logic_vector(BinOscs -1 downto 0);	
	type BinOscOutType is array(BinOscs-1 downto 0) of std_logic_vector(BinOscWidth-1 downto 0);
	signal BinOscOut: BinOscOutType;	
	signal LoadBinOscEnaSel: std_logic;	
	begin
		makebinoscs: for i in 0 to BinOscs -1 generate
			aBinOsc: entity work.binosc
			generic map (
				width => BinOscWidth
				)
			port map ( 
				clk => clklow,
				ibus0 => ibus(0),
				loadena => LoadBinOscEna(i),
				oscout => BinOscOut(i)		
				);
		end generate;
		
		BinOscDecodeProcess : process (A,writestb,LoadBinOscEnaSel)
		begin		
			if A(15 downto 8) = BinOscEnaAddr then	 	--  Charge Pump Power Supply enable decode
				LoadBinOscEnaSel <= '1';
			else
				LoadBinOscEnaSel <= '0';
			end if;
			LoadBinOscEna <= OneOfNDecode(BinOscs,LoadBinOscEnaSel,writestb,A(5 downto 2)); -- 16 max
		end process BinOscDecodeProcess;

		DoBinOscPins: process(BinOscOut)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = BinOscTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					AltData(i) <= BinOscOut(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(6 downto 0))-1);						
					report("External BinOscOutPin found");
				end if;
			end loop;	
		end process;

		DoLocalBinOscPins: process(BinOscOut) -- only for 4I69 LIO currently
		begin
			for i in 0 to LIOWidth -1 loop				-- loop through all the local I/O pins 
				if ThePinDesc(i+IOWidth)(15 downto 8) = BinOscTag then	-- GTag (Local I/O starts at end of external I/O)				
					LIOBits(i) <= BinOscOut(conv_integer(ThePinDesc(i+IOWidth)(23 downto 16)))(conv_integer(ThePinDesc(i+IOWIDTH)(6 downto 0))-1);						
					report("Local BinOscOutPin found");
				end if;	
			end loop;		
		end process;		
	end generate;

	makewavegenmod:  if WaveGens >0  generate	
	signal LoadWaveGenRate: std_logic_vector(WaveGens -1 downto 0);
	signal LoadWaveGenLength: std_logic_vector(WaveGens -1 downto 0);
	signal LoadWaveGenPDMRate: std_logic_vector(WaveGens -1 downto 0);
	signal LoadWaveGenTablePtr: std_logic_vector(WaveGens -1 downto 0);
	signal LoadWaveGenTableData: std_logic_vector(WaveGens -1 downto 0);
	signal WavegenPDMA: std_logic_vector(WaveGens -1 downto 0);
	signal WaveGenPDMB: std_logic_vector(WaveGens -1 downto 0);
	signal WaveGenTrigger0: std_logic_vector(WaveGens -1 downto 0);
	signal WaveGenTrigger1: std_logic_vector(WaveGens -1 downto 0);
	signal WaveGenTrigger2: std_logic_vector(WaveGens -1 downto 0);
	signal WaveGenTrigger3: std_logic_vector(WaveGens -1 downto 0);	
	signal WaveGenRateSel: std_logic;
	signal WaveGenLengthSel: std_logic;
	signal WaveGenPDMRateSel: std_logic;
	signal WaveGenTablePtrSel: std_logic;
	signal WaveGenTableDataSel: std_logic;	
	begin
		makewavegens: for i in 0 to WaveGens -1 generate
			awavegen:  entity work.wavegen	
			port map (
				clk => clklow,
				hclk => clkhigh,
				ibus => ibus,
--				obus => obus,
				loadrate => LoadWaveGenRate(i),
				loadlength => LoadWaveGenLength(i),
				loadpdmrate => LoadWaveGenPDMRate(i),
				loadtableptr => LoadWaveGenTablePtr(i),
				loadtabledata =>LoadWaveGenTableData(i),
				trigger0 => WaveGenTrigger0(i),
				trigger1 => WaveGenTrigger1(i),
				trigger2 => WaveGenTrigger2(i),
				trigger3 => WaveGenTrigger3(i),
				pdmouta => WaveGenPDMA(i),
				pdmoutb => WaveGenPDMB(i) 
				);
		end generate;
	
		WaveGenDecodeProcess : process (A,Readstb,writestb,WaveGenRateSel,WaveGenLengthSel,
			                             WaveGenPDMRateSel,WaveGenTablePtrSel,WaveGenTableDataSel)
		begin		
			if A(15 downto 8) = WaveGenRateAddr then	 --  WaveGen table index rate
				WaveGenRateSel <= '1';
			else
				WaveGenRateSel <= '0';
			end if;
			if A(15 downto 8) = WaveGenLengthAddr then	 --  WaveGen table length
				WaveGenlengthSel <= '1';
			else
				WaveGenlengthSel <= '0';
			end if;
			if A(15 downto 8) = WaveGenPDMRateAddr then	 --  WaveGen PDMRate
				WaveGenPDMRateSel <= '1';
			else
				WaveGenPDMRateSel <= '0';
			end if;
			if A(15 downto 8) = WaveGenTablePtrAddr then	 --  WaveGen TablePtr
				WaveGenTablePtrSel <= '1';
			else
				WaveGenTablePtrSel <= '0';
			end if;
			if A(15 downto 8) = WaveGenTableDataAddr then	 --  WaveGen TableData
				WaveGenTableDataSel <= '1';
			else
				WaveGenTableDataSel <= '0';
			end if;			
			LoadWaveGenRate <= OneOfNDecode(WaveGens,WaveGenRateSel,writestb,A(5 downto 2)); 
			LoadWaveGenLength <= OneOfNDecode(WaveGens,WaveGenLengthSel,writestb,A(5 downto 2));
			LoadWaveGenPDMRate <= OneOfNDecode(WaveGens,WaveGenPDMRateSel,writestb,A(5 downto 2));
			LoadWaveGenTablePtr <= OneOfNDecode(WaveGens,WaveGenTablePtrSel,writestb,A(5 downto 2));
			LoadWaveGenTableData <= OneOfNDecode(WaveGens,WaveGenTableDataSel,writestb,A(5 downto 2));
		end process WaveGenDecodeProcess;

		DoWaveGenPins: process(WaveGenPDMA, WaveGenPDMB, WaveGenTrigger0,
										WaveGenTrigger1, WaveGenTrigger2, WaveGenTrigger3)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = WaveGenTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function, drop MSB
						when PDMAOutPin =>
							AltData(i) <= WaveGenPDMA(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when PDMBOutPin =>
							AltData(i) <= WaveGenPDMB(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when Trigger0OutPin =>
							AltData(i) <= WaveGenTrigger0(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when Trigger1OutPin =>
							AltData(i) <= WaveGenTrigger1(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when Trigger2OutPin =>
							AltData(i) <= WaveGenTrigger2(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when Trigger3OutPin =>
							AltData(i) <= WaveGenTrigger3(conv_integer(ThePinDesc(i)(23 downto 16)));				
						when others => null;
					end case;		
				end if;
			end loop;	
		end process;
	end generate;
	
	makeresolvermod:  if ResolverMods >0  generate	
	signal LoadResModCommand: std_logic_vector(ResolverMods -1 downto 0);
	signal ReadResModCommand: std_logic_vector(ResolverMods -1 downto 0);
	signal LoadResModData: std_logic_vector(ResolverMods -1 downto 0);
	signal ReadResModData: std_logic_vector(ResolverMods -1 downto 0);           
	signal ReadResModStatus: std_logic_vector(ResolverMods -1 downto 0);           
	signal ReadResModVelRam: std_logic_vector(ResolverMods -1 downto 0); 
	signal ReadResModPosRam: std_logic_vector(ResolverMods -1 downto 0); 
	signal ResModPDMP: std_logic_vector(ResolverMods -1 downto 0);   
	signal ResModPDMM: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModSPICS: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModSPIClk: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModSPIDI0: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModSPIDI1: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModPwrEn: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModChan0: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModChan1: std_logic_vector(ResolverMods -1 downto 0);
	signal ResModChan2: std_logic_vector(ResolverMods -1 downto 0);	
	signal ResModTestBit: std_logic_vector(ResolverMods -1 downto 0);	
	signal ResModCommandSel: std_logic;
	signal ResModDataSel: std_logic;          
	signal ResModStatusSel: std_logic;          
	signal ResModVelRAMSel: std_logic; 
	signal ResModPosRAMSel: std_logic; 	
	
	begin
		makeresolvers: for i in 0 to ResolverMods -1 generate
			aresolver: entity work.resolver     
			generic map (
				Clock => ClockLow )
			port map (
				clk => clklow,
				ibus => ibus,
				obus => obus,
				hloadcommand => LoadResModCommand(i),
				hreadcommand => ReadResModCommand(i),
				hloaddata => LoadResModData(i),
				hreaddata => ReadResModData(i),           
				hreadstatus => ReadResModStatus(i),           
				regaddr => addr(4 downto 2), 		-- early address for DPRAM access
				readvel => ReadResModVelRam(i),
				readpos => ReadResModPosRam(i),
				testbit => ResModTestBit(i),
				respdmp => ResModPDMP(i),   
				respdmm => ResModPDMM(i),
				spics => ResModSPICS(i),
				spiclk => ResModSPIClk(i),
				spidi0 => ResModSPIDI0(i),
				spidi1 => ResModSPIDI1(i),
				pwren => ResModPwrEn(i),
				chan0 => ResModChan0(i),
				chan1 => ResModChan1(i),
				chan2 => ResModChan2(i)
				);
		end generate;

		ResolverModDecodeProcess : process (A,Readstb,writestb,ResModCommandSel,ResModDataSel,ResModVelRAMSel,ResModPosRAMSel)
		begin		
			if A(15 downto 8) = ResModCommandAddr then
				ResModCommandSel <= '1';
			else
				ResModCommandSel <= '0';
			end if;
			if A(15 downto 8) = ResModDataAddr then
				ResModDataSel <= '1';      
			else
				ResModDataSel <= '0';      
			end if;
			if A(15 downto 8) = ResModStatusAddr then
				ResModStatusSel <= '1';      
			else
				ResModStatusSel <= '0';      
			end if;
			if A(15 downto 8) = ResModVelRAMAddr then
				ResModVelRAMSel <= '1';
			else
				ResModVelRAMSel <= '0';
			end if;
			if A(15 downto 8) = ResModPosRAMAddr then
				ResModPosRAMSel <= '1';
			else
				ResModPosRAMSel <= '0';
			end if;			
			LoadResModCommand <= OneOfNDecode(ResolverMods,ResModCommandSel,writestb,A(7 downto 6)); 
			ReadResModCommand <= OneOfNDecode(ResolverMods,ResModCommandSel,Readstb,A(7 downto 6)); 
			LoadResModData <= OneOfNDecode(ResolverMods,ResModDataSel,writestb,A(7 downto 6)); 
			ReadResModData <= OneOfNDecode(ResolverMods,ResModDataSel,Readstb,A(7 downto 6));           
			ReadResModStatus <= OneOfNDecode(ResolverMods,ResModStatusSel,Readstb,A(7 downto 6));           
			ReadResModVelRam <= OneOfNDecode(ResolverMods,ResModVelRAMSel,Readstb,A(7 downto 6)); -- 16 addresses per resmod
			ReadResModPosRam <= OneOfNDecode(ResolverMods,ResModPosRAMSel,Readstb,A(7 downto 6)); -- 16 addresses per resmod
		end process ResolverModDecodeProcess;
		
		DoResModPins: process(ResModPwrEn,ResModChan2,ResModChan1,ResModChan0, 
									 ResModSPIClk,ResModSPICS,ResModPDMM,ResModPDMP)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = ResModTag then											
					case (ThePinDesc(i)(7 downto 0)) is	--secondary pin function
						when ResModPwrEnPin =>
							AltData(i) <= ResModPwrEn(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModPDMPPin =>
							AltData(i) <= ResModPDMP(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModPDMMPin =>
							AltData(i) <= ResModPDMM(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModChan0Pin =>
							AltData(i) <= ResModChan0(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModChan1Pin =>
							AltData(i) <= ResModChan1(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModChan2Pin =>
							AltData(i) <= ResModChan2(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModSPICSPin =>
							AltData(i) <= ResModSPICS(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModSPIClkPin =>
							AltData(i) <= ResModSPIClk(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModTestBitPin =>
							AltData(i) <= ResModTestBit(conv_integer(ThePinDesc(i)(23 downto 16))); 
						when ResModSPIDI0Pin =>
							ResModSPIDI0(conv_integer(ThePinDesc(i)(23 downto 16))) <= iobits(i); 
						when ResModSPIDI1Pin =>
							ResModSPIDI1(conv_integer(ThePinDesc(i)(23 downto 16))) <= iobits(i); 
						when others => null;
					end case;
				end if;
			end loop;
		end process;		
	end generate;

	makesserialmod:  if SSerials >0  generate	
	signal LoadSSerialCommand: std_logic_vector(SSerials -1 downto 0);
	signal ReadSSerialCommand: std_logic_vector(SSerials -1 downto 0);
	signal LoadSSerialData: std_logic_vector(SSerials -1 downto 0);
	signal ReadSSerialData: std_logic_vector(SSerials -1 downto 0);           
	signal LoadSSerialRAM0: std_logic_vector(SSerials -1 downto 0);
	signal ReadSSerialRAM0: std_logic_vector(SSerials -1 downto 0);           
	signal LoadSSerialRAM1: std_logic_vector(SSerials -1 downto 0);
	signal ReadSSerialRAM1: std_logic_vector(SSerials -1 downto 0);           
	signal LoadSSerialRAM2: std_logic_vector(SSerials -1 downto 0);
	signal ReadSSerialRAM2: std_logic_vector(SSerials -1 downto 0);        
	signal LoadSSerialRAM3: std_logic_vector(SSerials -1 downto 0);
	signal ReadSSerialRAM3: std_logic_vector(SSerials -1 downto 0);           
	type  SSerialRXType is array(SSerials-1 downto 0) of std_logic_vector(MaxUARTsPerSSerial-1 downto 0);
	signal SSerialRX: SSerialRXType;   
	type  SSerialTXType is array(SSerials-1 downto 0) of std_logic_vector(MaxUARTsPerSSerial-1 downto 0);
	signal SSerialTX: SSerialTXType;
	type  SSerialTXEnType is array(SSerials-1 downto 0) of std_logic_vector(MaxUARTsPerSSerial-1 downto 0);
	signal SSerialTXEn: SSerialTXEnType;
	signal SSerialTestBits: std_logic_vector(SSerials -1 downto 0);	
	signal SSerialCommandSel: std_logic;
	signal SSerialDataSel: std_logic;          
	signal SSerialRAMSel0: std_logic; 
	signal SSerialRAMSel1: std_logic; 
	signal SSerialRAMSel2: std_logic; 
	signal SSerialRAMSel3: std_logic; 
	begin
		makesserials: for i in 0 to SSerials -1 generate
			asserial: entity work.sserialwa     
			generic map (
				Ports => UARTSPerSSerial(i),
				InterfaceRegs => UARTSPerSSerial(i),	-- must be power of 2
				BaseClock => ClockMed,
				NeedCRC8 => true
			)
			port map( 
				clk  => clklow,
				clkmed => clkmed,
				ibus  => ibus,
				obus  => obus,
				hloadcommand  => LoadSSerialCommand(i),
				hreadcommand  => ReadSSerialCommand(i),
				hloaddata  => LoadSSerialData(i),
				hreaddata  => ReadSSerialData(i),           
				regaddr  =>  A(log2(UARTSPerSSerial(i))+1 downto 2),
				hloadregs0  => LoadSSerialRAM0(i),
				hreadregs0  => ReadSSerialRAM0(i),
				hloadregs1  => LoadSSerialRAM1(i),
				hreadregs1  => ReadSSerialRAM1(i),
				hloadregs2  => LoadSSerialRAM2(i),
				hreadregs2  => ReadSSerialRAM2(i),
				hloadregs3  => LoadSSerialRAM3(i),
				hreadregs3  => ReadSSerialRAM3(i),
				rxserial  =>  SSerialRX(i)(UARTSPerSSerial(i) -1 downto 0),
				txserial  =>  SSerialTX(i)(UARTSPerSSerial(i) -1 downto 0),
				txenable  =>  SSerialTXEn(i)(UARTSPerSSerial(i) -1 downto 0),
				testbit  =>   SSerialTestBits(i)
				);
		end generate;

		SSerialDecodeProcess : process (A,Readstb,writestb,SSerialCommandSel,SSerialDataSel,
		                                SSerialRAMSel0,SSerialRAMSel1,SSerialRAMSel2,SSerialRAMSel3)
		begin		
			if A(15 downto 8) = SSerialCommandAddr then
				SSerialCommandSel <= '1';
			else	
				SSerialCommandSel <= '0';
			end if;
			if A(15 downto 8) = SSerialDataAddr then
				SSerialDataSel <= '1';      
			else	
				SSerialDataSel <= '0';      
			end if;
			if A(15 downto 8) = SSerialRAMAddr0 then
				SSerialRAMSel0 <= '1'; 
			else	
				SSerialRAMSel0 <= '0'; 
			end if;
			if A(15 downto 8) = SSerialRAMAddr1 then
				SSerialRAMSel1 <= '1'; 
			else	
				SSerialRAMSel1 <= '0'; 
			end if;
			if A(15 downto 8) = SSerialRAMAddr2 then
				SSerialRAMSel2 <= '1'; 
			else	
				SSerialRAMSel2 <= '0'; 
			end if;
			if A(15 downto 8) = SSerialRAMAddr3 then
				SSerialRAMSel3 <= '1'; 
			else	
				SSerialRAMSel3 <= '0'; 
			end if;			
			LoadSSerialCommand <= OneOfNDecode(SSerials,SSerialCommandSel,writestb,A(7 downto 6)); 
			ReadSSerialCommand <= OneOfNDecode(SSerials,SSerialCommandSel,Readstb,A(7 downto 6)); 
			LoadSSerialData <= OneOfNDecode(SSerials,SSerialDataSel,writestb,A(7 downto 6)); 
			ReadSSerialData <= OneOfNDecode(SSerials,SSerialDataSel,Readstb,A(7 downto 6));           
			LoadSSerialRam0 <= OneOfNDecode(SSerials,SSerialRAMSel0,writestb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max, this implies 4 max sserials
			ReadSSerialRam0 <= OneOfNDecode(SSerials,SSerialRAMSel0,Readstb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max, this implies 4 max sserials
			LoadSSerialRam1 <= OneOfNDecode(SSerials,SSerialRAMSel1,writestb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max, this implies 4 max sserials
			ReadSSerialRam1 <= OneOfNDecode(SSerials,SSerialRAMSel1,Readstb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max
			LoadSSerialRam2 <= OneOfNDecode(SSerials,SSerialRAMSel2,writestb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max
			ReadSSerialRam2 <= OneOfNDecode(SSerials,SSerialRAMSel2,Readstb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max
			LoadSSerialRam3 <= OneOfNDecode(SSerials,SSerialRAMSel3,writestb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max
			ReadSSerialRam3 <= OneOfNDecode(SSerials,SSerialRAMSel3,Readstb,A(7 downto 6)); 	-- 16 addresses per SSerial RAM max
        report "Max UARTS per sserial " & integer'image(MaxUARTSPerSSerial);
        report "UARTS per sserial 0 " &  integer 'image(UARTSPerSSerial(0));
        report "UARTS per sserial 1 " &  integer 'image(UARTSPerSSerial(1));
        report "UARTS per sserial 2 " &  integer 'image(UARTSPerSSerial(2));
        report "UARTS per sserial 3 " &  integer 'image(UARTSPerSSerial(3));


		end process SSerialDecodeProcess;

		DoSSerialPins: process(SSerialTX, SSerialTXEn, SSerialTestBits, IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = SSerialTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					if (ThePinDesc(i)(7 downto 0) and x"F0") = x"80" then 	-- txouts match 8X 
						AltData(i) <=   SSerialTX(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(3 downto 0))-1);	-- 16 max ports			
					end if;
					if (ThePinDesc(i)(7 downto 0) and x"F0") = x"90" then 	-- txens match 9X
						AltData(i) <= not SSerialTXEn(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(3 downto 0))-1); 	-- 16 max ports						
					end if;
					if (ThePinDesc(i)(7 downto 0) and x"F0") = x"00" then 	-- rxins match 0X
						SSerialRX(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(3 downto 0))-1) <= IOBits(i);		-- 16 max ports			
					end if;
					if ThePinDesc(i)(7 downto 0) = SSerialTestPin then
						AltData(i) <= SSerialTestBits(i);
					end if;
				end if;
			end loop;
		end process;		
	end generate;

	maketwiddlermod:  if Twiddlers >0  generate		
	signal LoadTwiddlerCommand: std_logic_vector(Twiddlers -1 downto 0);
	signal ReadTwiddlerCommand: std_logic_vector(Twiddlers -1 downto 0);
	signal LoadTwiddlerData: std_logic_vector(Twiddlers -1 downto 0);
	signal ReadTwiddlerData: std_logic_vector(Twiddlers -1 downto 0);           
	signal LoadTwiddlerRAM: std_logic_vector(Twiddlers -1 downto 0);
	signal ReadTwiddlerRAM: std_logic_vector(Twiddlers -1 downto 0);           
	type  TwiddlerInputType is array(Twiddlers-1 downto 0) of std_logic_vector(InputsPerTwiddler-1 downto 0);
	signal TwiddlerInput: TwiddlerInputType;   
	type  TwiddlerOutputType is array(Twiddlers-1 downto 0) of std_logic_vector(OutputsPerTwiddler-1 downto 0);
	signal TwiddlerOutput: TwiddlerOutputType;
	signal TwiddlerCommandSel: std_logic;
	signal TwiddlerDataSel: std_logic;          
	signal TwiddlerRAMSel: std_logic; 
	begin
		maketwiddlers: for i in 0 to Twiddlers -1 generate
			atwiddler: entity work.twiddle     
			generic map (
				InterfaceRegs => RegsPerTwiddler,	-- must be power of 2
				InputBits => InputsPerTwiddler,
				OutputBits => OutputsPerTwiddler,
				BaseClock => ClockMed
			)
			port map( 
				clk  => clklow,
				clkmed => clkmed,
				ibus  => ibus,
				obus  => obus,
				hloadcommand  => LoadTwiddlerCommand(i),
				hreadcommand  => ReadTwiddlerCommand(i),
				hloaddata  => LoadTwiddlerData(i),
				hreaddata  => ReadTwiddlerData(i),           
				regraddr  =>  addr(log2(RegsPerTwiddler)+1 downto 2),	-- early address for DPRAM access
				regwaddr  =>  A(log2(RegsPerTwiddler)+1 downto 2),
				hloadregs  => LoadTwiddlerRAM(i),
				hreadregs  => ReadTwiddlerRAM(i),
				ibits  =>  TwiddlerInput(i),
				obits  =>  TwiddlerOutput(i)
--				testbit  =>   TwiddlerTestBits(i)
				);
		end generate;	

		TwiddleDecodeProcess : process (A,Readstb,writestb,TwiddlerCommandSel,TwiddlerDataSel,TwiddlerRAMSel)
		begin		
			if A(15 downto 8) = TwiddlerCommandAddr then
				TwiddlerCommandSel <= '1';
			else	
				TwiddlerCommandSel <= '0';
			end if;	
			if A(15 downto 8) = TwiddlerDataAddr then
				TwiddlerDataSel <= '1';      
			else	
				TwiddlerDataSel <= '0';      
			end if;
			if A(15 downto 8) = TwiddlerRAMAddr then
				TwiddlerRAMSel <= '1'; 
			else	
				TwiddlerRAMSel <= '0'; 
			end if;
			LoadTwiddlerCommand <= OneOfNDecode(Twiddlers,TwiddlerCommandSel,writestb,A(5 downto 2)); 
			ReadTwiddlerCommand <= OneOfNDecode(Twiddlers,TwiddlerCommandSel,Readstb,A(5 downto 2)); 
			LoadTwiddlerData <= OneOfNDecode(Twiddlers,TwiddlerDataSel,writestb,A(5 downto 2)); 
			ReadTwiddlerData <= OneOfNDecode(Twiddlers,TwiddlerDataSel,Readstb,A(5 downto 2));           
			LoadTwiddlerRam <= OneOfNDecode(Twiddlers,TwiddlerRAMSel,writestb,A(7 downto 6)); 	-- 16 addresses per Twiddle RAM max, this implies 4 max Twiddlers
			ReadTwiddlerRam <= OneOfNDecode(Twiddlers,TwiddlerRAMSel,Readstb,A(7 downto 6)); 	-- 16 addresses per Twiddle RAM max
		end process TwiddleDecodeProcess;

		DoTwiddlerPins: process(TwiddlerOutput)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = TwiddlerTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					if (ThePinDesc(i)(7 downto 0) and x"C0") = x"80" then 	-- outs match 8X .. BX 
						AltData(i) <=   TwiddlerOutput(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(5 downto 0))-1);	--  max ports, more than 8 requires adding to IDROM pins					
					end if;
					if (ThePinDesc(i)(7 downto 0) and x"C0") = x"00" then 	-- ins match 0X .. 3X
						TwiddlerInput(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(5 downto 0))-1) <= IOBits(i);		-- 16 max ports			
					end if;
					if (ThePinDesc(i)(7 downto 0) and x"C0") = x"C0" then 	-- I/Os match CX .. FX
						TwiddlerInput(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(5 downto 0))-1) <= IOBits(i);		-- 16 max ports			
						AltData(i) <= TwiddlerOutput(conv_integer(ThePinDesc(i)(23 downto 16)))(conv_integer(ThePinDesc(i)(4 downto 0))-1); 	-- 16 max ports						
					end if;
				end if;
			end loop;	
		end process;

	end generate;

	makescalercounters: if ScalerCounters >0 generate -- note scaler counter are in pairs	
	signal ReadScalerCount: std_logic_vector(ScalerCounters-1 downto 0);
	signal ReadScalerLatch: std_logic_vector(ScalerCounters-1 downto 0);
	signal SCCountInA: std_logic_vector(ScalerCounters -1 downto 0);
	signal SCCountInB: std_logic_vector(ScalerCounters -1 downto 0);
	signal ScalerCountSel: std_logic;
	signal ScalerLatchSel: std_logic;
	signal ReadScalerTimer: std_logic;

	begin
		scalertimerx : entity work.scalertimer
				port map (				
					obus => obus,
					readtimer => ReadScalerTimer,
					clk => clklow
					);

		makescalercounters: for i in 0 to ScalerCounters-1 generate
			scalercounterx: entity work.scalercounter 
				port map (
					obus => obus,
					countina => SCCountInA(i),
					countinb => SCCountInB(i),
					readcount => ReadScalerCount(i),
					readlatch => ReadScalerLatch(i),
					latch => ReadScalerTimer,
					clk =>	clklow
				);
		end generate;
			
		DoScalerCounterPins: process(IOBits)
		begin	
			for i in 0 to IOWidth -1 loop				-- loop through all the external I/O pins 
				if ThePinDesc(i)(15 downto 8) = ScalerCounterTag then 	-- this hideous masking of pinnumbers/vs pintype is why they should be separate bytes, maybe IDROM type 4...											
					if (ThePinDesc(i)(7 downto 0)) = ScalerCounterInA then
						SCCountInA(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
					end if;
					if (ThePinDesc(i)(7 downto 0)) = ScalerCounterInB then
						SCCountInB(conv_integer(ThePinDesc(i)(23 downto 16))) <= IOBits(i);
					end if;
				end if;
			end loop;	
		end process;
		
		ScalerDecodeProcess : process (A,Readstb,ScalerCountSel,ScalerLatchSel)
		begin		
			if A(15 downto 8) = ScalerCountAddr then	 --  
				ScalerCountSel <= '1';
			else
				ScalerCountSel <= '0';
			end if;

			if A(15 downto 8) = ScalerLatchAddr then	 --  
				ScalerLatchSel <= '1';
			else
				ScalerLatchSel <= '0';
			end if;

			if A(15 downto 8) = ScalerTimerAddr and readstb = '1' then	 --  
				ReadScalerTimer <= '1';
			else
				ReadScalerTimer <= '0';
			end if;
			
			ReadScalerCount <= OneOfNDecode(ScalerCounters,ScalerCountSel,readstb,A(7 downto 2)); 
			ReadScalerLatch <= OneOfNDecode(ScalerCounters,ScalerLatchSel,readstb,A(7 downto 2)); 
		end process ScalerDecodeProcess;
		
	end generate;	

	
	LEDReg : entity work.boutreg 
	generic map (
		size => LEDCount,
		buswidth => LEDCount,
		invert => true)
	port map (
		clk  => clklow,
		ibus => ibus(BusWidth-1 downto BusWidth-LEDCount),
		obus => obus(BusWidth-1 downto BusWidth-LEDCount),
		load => LoadLEDs,
		read => '0',
		clear => '0',
		dout => LEDS
		); 

		
	IDROMWP : entity work.boutreg 
 		generic map (
			size => 1,
			buswidth => BusWidth,
			invert => false
			)
		port map (
			clk  => clklow,
         ibus => ibus,
         obus => obus,
         load => LoadIDROMWEn,
         read => ReadIDROMWEn,
			clear => '0',
         dout => IDROMWen
		); 
		 		

	IDROM : entity work.IDROM
		generic map (
			idromtype => IDROMType,
			offsettomodules => OffsetToModules,
			offsettopindesc => OffsetToPinDesc,
			boardnamelow => BoardNameLow,
			boardnameHigh => BoardNameHigh,
			fpgasize => FPGASize,
			fpgapins => FPGAPins,
			ioports => IOPorts,
			iowidth => IOWidth,
			portwidth => PortWidth,		
			clocklow => ClockLow,
			clockhigh => ClockHigh,
			inststride0 => InstStride0,
			inststride1 => InstStride1,
			regstride0 => RegStride0,
			regstride1 => RegStride1,
			pindesc => ThePinDesc,
			moduleid => TheModuleID)
		port map (
			clk  => clklow, 
			we   => LoadIDROM,
			re   => ReadIDROM,
			radd => addr(9 downto 2),
			wadd => A(9 downto 2),
			din  => ibus, 
			dout => obus
		); 
				
   LooseEnds: process(A,clklow)
	begin
		if rising_edge(clklow) then
			A <= addr;
		end if;
	end process;
	
--   MuxedEncMIM: if  MuxedQCountersMIM > 0 generate
--	
--		EncoderDeMuxMIM: process(clklow)
--		begin
--			if rising_edge(clklow) then
--				if MuxedQCountFilterRate = '1' then
--					PreMuxedQCtrSel <= PreMuxedQCtrSel + 1;
--				end if;
--				MuxedQCtrSel <= PreMuxedQCtrSel;
--				for i in 0 to ((MuxedQCounters/2) -1) loop -- just 2 deep for now
--					if PreMuxedQCtrSel(0) = '1' and MuxedQCtrSel(0) = '0' then	-- latch the even inputs	
--						DeMuxedQuadA(2*i) <= MuxedQuadA(i);
--						DeMuxedQuadB(2*i) <= MuxedQuadB(i);
--						DeMuxedIndex(2*i) <= MuxedIndex(i);
--						DeMuxedIndexMask(2*i) <= MuxedIndexMask(i);
--					end if;
--					if PreMuxedQCtrSel(0) = '0' and MuxedQCtrSel(0) = '1' then	-- latch the odd inputs
--						DeMuxedQuadA(2*i+1) <= MuxedQuadA(i);
--						DeMuxedQuadB(2*i+1) <= MuxedQuadB(i);
--						DeMuxedIndex(2*i+1) <= MuxedIndex(i);
--						DeMuxedIndexMask(2*i+1) <= MuxedIndexMask(i);
--					end if;
--				end loop;
--			end if; -- clk
--		end process;
--	end generate;		
	

	Decode: process(A,writestb, IDROMWEn, readstb) 
	begin	
		-- basic multi decodes are at 256 byte increments (64 longs)
		-- first decode is 256 x 32 ID ROM
		-- these need to all be updated to the decoded strobe function instead of if_then_else

		if (A(15 downto 10) = IDROMAddr(7 downto 2)) and writestb = '1' and IDROMWEn = "1" then	 -- 400 Hex  
			LoadIDROM <= '1';
		else
			LoadIDROM <= '0';
		end if;
		if (A(15 downto 10) = IDROMAddr(7 downto 2)) and readstb = '1' then	 --  
			ReadIDROM <= '1';
		else
			ReadIDROM <= '0';
		end if;

		if A(15 downto 8) = PortAddr then  -- basic I/O port select
			PortSel <= '1';
		else
			PortSel <= '0';
		end if;

		if A(15 downto 8) = DDRAddr then	 -- DDR register select
			DDRSel <= '1';
		else
			DDRSel <= '0';
		end if;

		if A(15 downto 8) = AltDataSrcAddr then  -- Alt data source register select
			AltDataSrcSel <= '1';
		else
			AltDataSrcSel <= '0';
		end if;

		if A(15 downto 8) = OpenDrainModeAddr then	 --  OpenDrain  register select
			OpendrainModeSel <= '1';
		else
			OpenDrainModeSel <= '0';
		end if;

		if A(15 downto 8) = OutputInvAddr then	 --  IO invert register select
			OutputInvSel <= '1';
		else
			OutputInvSel <= '0';
		end if;

		if A(15 downto 8) = ReadIDAddr and readstb = '1' then	 --  
			ReadID <= '1';
		else
			ReadID <= '0';
		end if;

		if A(15 downto 8) = WatchdogTimeAddr and readstb = '1' then	 --  
			ReadWDTime <= '1';
		else
			ReadWDTime <= '0';
		end if;
		if A(15 downto 8) = WatchdogTimeAddr and writestb = '1' then	 --  
			LoadWDTime <= '1';
		else
			LoadWDTime <= '0';
		end if;

		if A(15 downto 8) = WatchdogStatusAddr and readstb = '1' then	 --  
			ReadWDStatus <= '1';
		else
			ReadWDStatus <= '0';
		end if;
		if A(15 downto 8) = WatchdogStatusAddr and writestb = '1' then	 --  
			LoadWDStatus <= '1';
		else
			LoadWDStatus <= '0';
		end if;

		if A(15 downto 8) = WatchdogCookieAddr and writestb = '1' then	 --  
			WDCookie <= '1';
		else
			WDCookie <= '0';
		end if;

		if A(15 downto 8) = DMDMAModeAddr and writestb = '1' then	 --  
			LoadDMDMAMode <= '1';
		else
			LoadDMDMAMode <= '0';
		end if;

		if A(15 downto 8) = DMDMAModeAddr and readstb = '1' then	 --  
			ReadDMDMAMode <= '1';
		else
			ReadDMDMAMode <= '0';
		end if;
 		
		if A(15 downto 8) = IDROMWEnAddr and writestb = '1' then	 --  
			LoadIDROMWEn <= '1';
		else
			LoadIDROMWEn <= '0';
		end if;
	
		if A(15 downto 8) = IDROMWEnAddr and readstb = '1' then	 --  
			ReadIDROMWEn <= '1';
		else
			ReadIDROMWEn <= '0';
		end if;

		if A(15 downto 8) = LEDAddr and writestb = '1' then	 --  
			LoadLEDs <= '1';
		else
			LoadLEDs <= '0';
		end if;

	end process;
	
	PortDecode: process (A,readstb,writestb,PortSel, DDRSel, AltDataSrcSel, OpenDrainModeSel, OutputInvSel)
	begin

		LoadPortCMD <= OneOfNDecode(IOPorts,PortSel,writestb,A(4 downto 2)); -- 8 max
		ReadPortCMD <= OneOfNDecode(IOPorts,PortSel,readstb,A(4 downto 2));
		LoadDDRCMD <= OneOfNDecode(IOPorts,DDRSel,writestb,A(4 downto 2));
		ReadDDRCMD <= OneOfNDecode(IOPorts,DDRSel,readstb,A(4 downto 2));

		LoadAltDataSrcCMD <= OneOfNDecode(IOPorts,AltDataSrcSel,writestb,A(4 downto 2));
		LoadOpenDrainModeCMD <= OneOfNDecode(IOPorts,OpenDrainModeSel,writestb,A(4 downto 2));
		LoadOutputInvCMD <= OneOfNDecode(IOPorts,OutputInvSel,writestb,A(4 downto 2));

	end process PortDecode;
				
	dotieupint: if not UseIRQLogic generate
		tieupint : process(clklow)
		begin
			INT <= '1';
		end process;
	end generate;		
	
	drqrouting: if UseDemandModeDMA generate

	end generate;	
	
end dataflow;

  