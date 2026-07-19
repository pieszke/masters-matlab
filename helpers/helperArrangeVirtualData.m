function virtualData = helperArrangeVirtualData(data,radarConfiguration)
    % https://www.mathworks.com/help/radar/ug/iq-data-collection-detection-application-example.html
    % Arrange data into virtual data cube

    nTx = radarConfiguration.NumTransmitters;
    nRx = radarConfiguration.NumReceivers;
    nSamples = radarConfiguration.SamplesPerChirp;
    nChirps = radarConfiguration.NumChirps;
    virtualData = zeros(nSamples,nRx*nTx,nChirps/nTx);
    for iTx = 0:nTx-1
        startIdx = iTx*nRx+1;
        endIdx = startIdx+nRx-1;
        virtualData(:,startIdx:endIdx,:) = data(:,:,iTx+1:nTx:end);
    end
end

