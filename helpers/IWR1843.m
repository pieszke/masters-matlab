classdef IWR1843
    %IWR1843 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        lambda = 3.8e-3; % measured from design files
        scanAnglesRange=[-70 70];
        angleArray;
        rxArray;
        vArray;
        config;
        rResponse;
        rdResponse;
        mvdrEstimator;
        musicEstimator;
    end

    methods
        function obj = IWR1843(radarConfigurationOrPath)
            if isstring(radarConfigurationOrPath)
                if isfolder(radarConfigurationOrPath)
                    radarConfigurationOrPath = fileWithSuffix(radarConfigurationOrPath,"ers.mat");
                end
                radarConfiguration=load(radarConfigurationOrPath,"RecordingParameters").RecordingParameters;
            else
                radarConfiguration = radarConfigurationOrPath;
            end
            obj.config = radarConfiguration;
            el = phased.CosineAntennaElement('CosinePower',[2.20 17.5]);
            nRx = 4; 
            obj.rxArray = phased.ULA(Element=el,ElementSpacing=obj.lambda/2,NumElements=nRx,ArrayAxis="x");
            
            nTx = 3;
            txPos = [1;0;0]*(0:nTx-1)*obj.lambda;
            txPos(3,2)=obj.lambda/2;

            obj.vArray = phased.ReplicatedSubarray(Subarray=obj.rxArray,Layout="Custom",SubarrayPosition=txPos,SubarrayNormal=zeros(2,nTx));
            obj.angleArray = phased.ULA(Element=el,ElementSpacing=obj.lambda/2,NumElements=nRx*2,ArrayAxis="x");

            fs = radarConfiguration.ADCSampleRate*1e3;
            sweepSlope = radarConfiguration.SweepSlope*1e6/1e-6;
            fc = radarConfiguration.CenterFrequency*1e9;
            prf = 1e6/(radarConfiguration.NumTransmitters*radarConfiguration.ChirpCycleTime);

            obj.rdResponse = phased.RangeDopplerResponse( ...
                RangeMethod="FFT",...
                DechirpInput=false,...
                SampleRate=fs,...
                SweepSlope=sweepSlope,...
                DopplerOutput='Speed',...
                OperatingFrequency=fc,...
                PRFSource='Property', PRF=prf,...
                ReferenceRangeCentered=false,...
                RangeWindow='Hamming',...
                DopplerWindow="Hamming");

            obj.rResponse= phased.RangeResponse( ...
                'RangeMethod','FFT', ...
                'SampleRate',fs, ...
                'SweepSlope',sweepSlope, ...
                'DechirpInput',false, ...
                'RangeWindow','Hamming', ...
                'ReferenceRangeCentered',false);
            
            scanAngles = obj.scanAnglesRange(1):obj.scanAnglesRange(2);
            obj.mvdrEstimator = phased.MVDREstimator( ...
                SensorArray=obj.angleArray,OperatingFrequency=fc, ...
                ScanAngles=scanAngles);
            obj.musicEstimator=phased.MUSICEstimator('SensorArray',obj.angleArray,...
                'OperatingFrequency',fc,'ScanAngles',scanAngles);
        end

        function virtualData = arrangeVirtualData(obj,data)
            % data is cell or array loaded using dca.read()
            if iscell(data)
                data = data{1};
            end
            % data is a frame array with dimensions [range,rx,chirps]
            nTx = sum(obj.config.ActiveTransmitters);
            nRx = size(data, 2);
            if nRx~=sum(obj.config.ActiveReceivers)
                error("Invalid data size for loaded configuration")
            end
            nSamples = obj.config.SamplesPerChirp;
            nChirps = size(data, 3);
            nChirpsPerTx = floor(nChirps / nTx); % data can be cut at non divisible chirp number
            virtualData = zeros(nSamples, nRx * nTx, nChirpsPerTx);
            for iTx = 0:nTx-1
                startIdx = iTx*nRx+1;
                endIdx = startIdx+nRx-1;
                virtualData(:,startIdx:endIdx,:) = data(:,:,iTx+1:nTx:end);
            end
        end
        function virtualData = arrangeVirtualDataAngleULA(obj,data)
            virtualData = obj.arrangeVirtualData(data);
            tx = obj.config.ActiveTransmitters;
            if sum(tx)==3
                virtualData = virtualData(:,[1:4 9:12],:);
            elseif sum(tx([1 3]))==2
                return
            else
                error("Invalid config for angleArray")
            end
        end
    end
    methods (Static)
        function viewArr(array,title)
            figure;
            viewArray(array,"Title",title)
            axis tight
            set(gcf, "Theme", "light")
            set(gca, "XGrid", "off", "YGrid", "off", "ZGrid", "on")
        end
    end
end

function path = fileWithSuffix(folder,suffix)
opts = dir(folder+"\*"+suffix);
path = folder+"\"+opts(1).name;
end