clear all
%% csireader.m
%
% read and plot CSI from UDPs created using the nexmon CSI extractor (nexmon.org/csi)
% modify the configuration section to your needs
% make sure you run >mex unpack_float.c before reading values from bcm4358 or bcm4366c0 for the first time
%
% the example.pcap file contains 4(core 0-1, nss 0-1) packets captured on a bcm4358
%

%% configuration
CHIP = '43455c0';          % wifi chip (possible values 4339, 4358, 43455c0, 4366c0)
BW = 80;                % bandwidth
FILE = '/home/dennisherell/pcap/28Jan2021/n15x88.pcap';% capture file
NPKTS_MAX = 1000;       % max number of UDPs to process

%% read file
HOFFSET = 16;           % header offset
NFFT = BW*3.2;          % fft size, number of total subcarrier (not usable subcarrier though)

p = readpcap(); % Create p as an object of readpcap class      
p.open(FILE); % Extract the fid and global header from the .pcap file
n = min(length(p.all()),NPKTS_MAX); % p.all is a list of all frame data
p.from_start(); % Reset the file pointer location to the start of frame data

csi_buff = complex(zeros(n,NFFT),0);
% zeros(n,NFFT) return a matrix of n x NFFT size containing zeroes
% csi_buff is a matrix of n x NFFT size containing complex value
k = 1;
while (k <= n)
    f = p.next(); % Check the frame one by one
    if isempty(f) % If it's empty
        disp('no more frames');
        break;
    end
    % The correct data frame size (in bytes) is NFFT * 4, if not
    if f.header.orig_len-(HOFFSET-1)*4 ~= NFFT*4 
        disp('skipped frame with incorrect size');
        continue;
    end
    payload = f.payload; % put the frame payload into local variable
    H = payload(HOFFSET:HOFFSET+NFFT-1); % The csi value can be gotten after Hoffset
    
    % Check for chip version
    if (strcmp(CHIP,'4339') || strcmp(CHIP,'43455c0'))
    % For raspberry pi (43455c0), change the payload from 
    % uint32 / uint8 --> int16 (stored in Hout)
        Hout = typecast(H, 'int16'); 
    elseif (strcmp(CHIP,'4358'))
        Hout = unpack_float(int32(0), int32(NFFT), H);
    elseif (strcmp(CHIP,'4366c0'))
        Hout = unpack_float(int32(1), int32(NFFT), H);
    else
        disp('invalid CHIP');
        break;
    end
    
    Hout = reshape(Hout,2,[]).'; % reshape Hout into 2 column matrix and transpose it
    % The first column contain real value, second imaginary value
    cmplx = double(Hout(1:NFFT,1))+1j*double(Hout(1:NFFT,2));
    % Transpose cmplx from 64x1 into 1x64 and add it into csi_buff
    % add the frame csi value into csi_buff
    csi_buff(k,:) = cmplx.';
    
    % Remove the null subcarrier for 20 MHz
    if(BW == 20)
        csi_buff(k,1) = 0;
        i = 27;
        while(i<=37)
            csi_buff(k,i) = 0;
            i = i + 1;
        end
    elseif(BW == 40)
        csi_buff(k,1) = 0;
        csi_buff(k,128) = 0;
        i = 60;
        while(i<=68)
            csi_buff(k,i) = 0;
            i = i + 1;
        end
    else
        csi_buff(k,1) = 0;
        csi_buff(k,2) = 0;
        i = 124;
        while(i<=132)
            csi_buff(k,i) = 0;
            i = i + 1;
        end
    end
    % Repeat the loop for the next frame
    k = k + 1;
end

%% plot
plotcsi(csi_buff, NFFT, true)