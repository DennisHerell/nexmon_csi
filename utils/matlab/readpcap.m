classdef readpcap < handle % Create a class with class name readpcap and superclassname handle
    %READPCAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties % The class has 3 values: fid, global_header, and prev_len
        fid;
        global_header;
        prev_len;
    end
    
    methods % readpcap has 4 function associated with it
        function open(obj, filename) % filename will be the pcap file
            obj.fid = fopen(filename); %open the file for binary read access
            
            % 7 parameter to be read
            % fread syntax: fread(fileID, data array size, size of data)
            % fread position the file pointer after the last value read
            % should be 0xA1B2C3D4
            obj.global_header.magic_number = fread(obj.fid, 1, '*uint32');

            % major version number
            obj.global_header.version_major = fread(obj.fid, 1, '*uint16');

            % minor version number
            obj.global_header.version_minor = fread(obj.fid, 1, '*uint16');

            % GMT to local correction
            obj.global_header.thiszone = fread(obj.fid, 1, '*int32');

            % accuracy of timestamps
            obj.global_header.sigfigs = fread(obj.fid, 1, '*uint32');

            % max length of captured packets, in octets
            obj.global_header.snaplen = fread(obj.fid, 1, '*uint32');

            % data link type
            obj.global_header.network = fread(obj.fid, 1, '*uint32');
        end
        
        function frame = next(obj) % Read the data of each frame
            % timestamp seconds
            frame.header.ts_sec = fread(obj.fid, 1, '*uint32');

            % timestamp microseconds
            frame.header.ts_usec = fread(obj.fid, 1, '*uint32');

            % number of octets of packet saved in file
            frame.header.incl_len = fread(obj.fid, 1, '*uint32');

            % actual length of packet
            frame.header.orig_len = fread(obj.fid, 1, '*uint32');

            if isempty(frame.header.incl_len)
                frame = [];
                return;
            end

            % packet data
            if (mod(frame.header.incl_len,4)==0) % If number of octets of packet is a multiple of 4
                frame.payload = fread(obj.fid, frame.header.incl_len/4, '*uint32'); % The payload is 4 bytes uint32
            else
                frame.payload = fread(obj.fid, frame.header.incl_len, '*uint8'); % Otherwise, read it for 1 byte
            end
        end
        
        function from_start(obj)
            % fseek syntax: fseek(fileID, offset, origin)
            % Move the file position indicator 24 bytes from -1, which is
            % after the global header information
            fseek(obj.fid, 24, -1);
        end
        
        function frames = all(obj)
            i = 1;
            frames = cell(1); %  frames is a 1 by 1 array of empty matrices
            obj.from_start(); % Move the file position to after the global header info
            while true
                frame = obj.next(); % read the frame data

                if isempty(frame) % if empty, finish. if not, continue to read
                    break;
                end
                % frames will become a list of all the frame data
                frames{i} = frame;
                i = i + 1;
            end
        end
    end
    
end

