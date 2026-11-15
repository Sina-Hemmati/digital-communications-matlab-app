classdef CommLabAppV6_1 < matlab.apps.AppBase
    % CommLabAppV6_1
    % Digital Communications Laboratory Simulator
    %   app = CommLabAppV6_1;

    properties (Access = public)
        UIFigure
        MainGrid
        TitleLabel

        ModPanel
        ChannelPanel
        DemodPanel

        SchemeDropDown
        InputValueLabel

        Param1Label
        Param1Slider
        Param1ValueLabel
        Param2Label
        Param2Slider
        Param2ValueLabel
        Param3Label
        Param3Slider
        Param3ValueLabel

        SNRSlider
        SNRValueLabel
        GainSlider
        GainValueLabel

        ModAxes
        InputBitsAxes
        ChannelAxes
        DemodAxes
        RecoveredBitsAxes

        ModInfoLabel
        ChannelInfoLabel
        MetricLabel
        BitsLabel
        StatusLabel

        NewInputButton
    end

    properties (Access = private)
        IsUpdating logical = false
        SourceBits double = []
        SourceMessage double = []
        SourceTime double = []
        CurrentScheme string = ""
    end

    methods (Access = private)

        function startupFcn(app)
            app.configureSchemeControls();
            app.generateNewInput();
        end

        function configureSchemeControls(app)
            scheme = app.SchemeDropDown.Value;
            app.CurrentScheme = string(scheme);

            switch scheme
                case 'ASK'
                    app.Param1Label.Text = 'Carrier frequency (kHz)';
                    app.setSlider(app.Param1Slider, [1 20], 5);

                    app.Param2Label.Text = 'Bit rate (bit/s)';
                    app.setSlider(app.Param2Slider, [100 2000], 1000);

                    app.Param3Label.Text = 'Amplitude';
                    app.setSlider(app.Param3Slider, [0.1 5], 1);

                    app.InputValueLabel.Text = 'Random bits';

                case 'FSK'
                    app.Param1Label.Text = 'Mark frequency (kHz)';
                    app.setSlider(app.Param1Slider, [2 20], 8);

                    app.Param2Label.Text = 'Space frequency (kHz)';
                    app.setSlider(app.Param2Slider, [1 18], 4);

                    app.Param3Label.Text = 'Bit rate (bit/s)';
                    app.setSlider(app.Param3Slider, [100 2000], 1000);

                    app.InputValueLabel.Text = 'Random bits';

                case 'PWM'
                    app.Param1Label.Text = 'Message frequency (Hz)';
                    app.setSlider(app.Param1Slider, [0.5 10], 2);

                    app.Param2Label.Text = 'PWM carrier (Hz)';
                    app.setSlider(app.Param2Slider, [20 150], 60);

                    app.Param3Label.Text = 'Message amplitude';
                    app.setSlider(app.Param3Slider, [0.1 1], 0.8);

                    app.InputValueLabel.Text = 'Sine wave';

                case 'CVSD'
                    app.Param1Label.Text = 'Message frequency (Hz)';
                    app.setSlider(app.Param1Slider, [0.5 10], 2);

                    app.Param2Label.Text = 'Sampling frequency (Hz)';
                    app.setSlider(app.Param2Slider, [50 500], 200);

                    app.Param3Label.Text = 'Initial step size';
                    app.setSlider(app.Param3Slider, [0.005 0.2], 0.04);

                    app.InputValueLabel.Text = 'Sine wave';

                case 'DM'
                    app.Param1Label.Text = 'Message frequency (Hz)';
                    app.setSlider(app.Param1Slider, [0.5 10], 2);

                    app.Param2Label.Text = 'Sampling frequency (Hz)';
                    app.setSlider(app.Param2Slider, [50 500], 200);

                    app.Param3Label.Text = 'Step size';
                    app.setSlider(app.Param3Slider, [0.005 0.2], 0.04);

                    app.InputValueLabel.Text = 'Sine wave';
            end

            app.updateValueLabels();
        end

        function setSlider(~, slider, limits, value)
            slider.Limits = limits;
            slider.Value = value;
            slider.MajorTicks = linspace(limits(1), limits(2), 5);
        end

        function schemeChanged(app, ~)
            app.configureSchemeControls();
            app.generateNewInput();
        end

        function generateNewInput(app, ~)
            switch app.SchemeDropDown.Value
                case {'ASK','FSK'}
                    app.SourceBits = randi([0 1], 1, 100);
                    app.SourceMessage = [];
                    app.SourceTime = [];
                otherwise
                    app.SourceBits = [];
                    app.SourceMessage = [];
                    app.SourceTime = [];
            end
            app.updateSimulation();
        end

        function sliderChanging(app, event, whichSlider)
            switch whichSlider
                case 'p1'
                    app.Param1Slider.Value = event.Value;
                case 'p2'
                    app.Param2Slider.Value = event.Value;
                case 'p3'
                    app.Param3Slider.Value = event.Value;
                case 'snr'
                    app.SNRSlider.Value = event.Value;
                case 'gain'
                    app.GainSlider.Value = event.Value;
            end
            app.updateValueLabels();
            app.updateSimulation();
        end

        function sliderChanged(app, ~)
            app.updateValueLabels();
            app.updateSimulation();
        end


        function updateValueLabels(app)
            app.Param1ValueLabel.Text = sprintf('%.3g', app.Param1Slider.Value);
            app.Param2ValueLabel.Text = sprintf('%.3g', app.Param2Slider.Value);
            app.Param3ValueLabel.Text = sprintf('%.3g', app.Param3Slider.Value);
            app.SNRValueLabel.Text = sprintf('%.1f dB', app.SNRSlider.Value);
            app.GainValueLabel.Text = sprintf('%.1f dB', app.GainSlider.Value);
        end

        function updateSimulation(app)
            if app.IsUpdating
                return;
            end

            app.IsUpdating = true;
            cleanup = onCleanup(@() app.finishUpdate());

            try
                snrDb = app.SNRSlider.Value;
                gainDb = app.GainSlider.Value;
                scheme = app.SchemeDropDown.Value;

                switch scheme
                    case 'ASK'
                        result = app.simulateASK(snrDb, gainDb);
                    case 'FSK'
                        result = app.simulateFSK(snrDb, gainDb);
                    case 'PWM'
                        result = app.simulatePWM(snrDb, gainDb);
                    case 'CVSD'
                        result = app.simulateCVSD(snrDb, gainDb);
                    case 'DM'
                        result = app.simulateDM(snrDb, gainDb);
                end

                app.drawMainAxes(result, scheme);
                app.drawInputBits(result, scheme);
                app.drawRecoveredBits(result, scheme);

                app.ModInfoLabel.Text = result.info;
                app.ChannelInfoLabel.Text = ...
                    sprintf('AWGN channel | SNR = %.1f dB | Gain = %.1f dB', snrDb, gainDb);
                app.MetricLabel.Text = result.metric;
                app.BitsLabel.Text = result.bitsText;

                app.StatusLabel.Text = sprintf( ...
                    '%s simulation | SNR %.1f dB | Channel gain %.1f dB', ...
                    scheme, snrDb, gainDb);

            catch ME
                app.StatusLabel.Text = ['Error: ' ME.message];
            end
        end

        function finishUpdate(app)
            app.IsUpdating = false;
        end

        function drawMainAxes(app, result, scheme)

            cla(app.ModAxes);
            plot(app.ModAxes, result.t, result.tx, ...
                'Color', [0.10 0.45 1.00], 'LineWidth', 1.15);
            app.formatAxes(app.ModAxes, [scheme ' modulator output'], result.t, result.displayEnd);

            cla(app.ChannelAxes);
            plot(app.ChannelAxes, result.t, result.rx, ...
                'Color', [0.95 0.20 0.18], 'LineWidth', 1.0);
            app.formatAxes(app.ChannelAxes, 'Channel output', result.t, result.displayEnd);

            cla(app.DemodAxes);
            plot(app.DemodAxes, result.t, result.recovered, ...
                'Color', [0.15 0.75 0.25], 'LineWidth', 1.25);
            app.formatAxes(app.DemodAxes, result.recoveredTitle, result.t, result.displayEnd);
        end

        function formatAxes(~, ax, plotTitle, t, displayEnd)
            grid(ax, 'on');
            title(ax, plotTitle, 'Color', [0.08 0.08 0.08], ...
                'FontWeight', 'bold');
            xlabel(ax, 'Time (s)', 'Color', [0.12 0.12 0.12]);
            ylabel(ax, 'Amplitude', 'Color', [0.12 0.12 0.12]);
            ax.XColor = [0.15 0.15 0.15];
            ax.YColor = [0.15 0.15 0.15];
            ax.GridColor = [0.60 0.60 0.60];
            ax.GridAlpha = 0.28;
            ax.Color = [1 1 1];
            xlim(ax, [t(1) displayEnd]);
        end

        function drawInputBits(app, result, scheme)
            cla(app.InputBitsAxes);

            if ismember(scheme, {'ASK','FSK'})
                stairs(app.InputBitsAxes, result.t, result.reference, ...
                    'Color', [0.10 0.45 1.00], 'LineWidth', 1.6);
                ylim(app.InputBitsAxes, [-0.15 1.15]);
                ylabel(app.InputBitsAxes, 'Bit');
                title(app.InputBitsAxes, 'Input bits');
            else
                plot(app.InputBitsAxes, result.t, result.reference, ...
                    'Color', [0.10 0.45 1.00], 'LineWidth', 1.15);
                ylabel(app.InputBitsAxes, 'Amplitude');
                title(app.InputBitsAxes, 'Input message');
            end

            grid(app.InputBitsAxes, 'on');
            xlabel(app.InputBitsAxes, 'Time (s)');
            app.InputBitsAxes.XColor = [0.15 0.15 0.15];
            app.InputBitsAxes.YColor = [0.15 0.15 0.15];
            app.InputBitsAxes.GridColor = [0.60 0.60 0.60];
            app.InputBitsAxes.GridAlpha = 0.28;
            app.InputBitsAxes.Color = [1 1 1];
            xlim(app.InputBitsAxes, [result.t(1) result.displayEnd]);
        end

        function drawRecoveredBits(app, result, scheme)
            cla(app.RecoveredBitsAxes);

            if ismember(scheme, {'ASK','FSK'})
                stairs(app.RecoveredBitsAxes, result.t, result.bitWave, ...
                    'Color', [0.15 0.75 0.25], 'LineWidth', 1.6);
                ylim(app.RecoveredBitsAxes, [-0.15 1.15]);
                ylabel(app.RecoveredBitsAxes, 'Bit');
                title(app.RecoveredBitsAxes, 'Recovered bits');
            else
                plot(app.RecoveredBitsAxes, result.t, result.reference, ...
                    '--', 'Color', [0.20 0.35 0.85], 'LineWidth', 1.0);
                hold(app.RecoveredBitsAxes, 'on');
                plot(app.RecoveredBitsAxes, result.t, result.recovered, ...
                    'Color', [0.15 0.75 0.25], 'LineWidth', 1.15);
                hold(app.RecoveredBitsAxes, 'off');
                ylabel(app.RecoveredBitsAxes, 'Amplitude');
                title(app.RecoveredBitsAxes, 'Original and reconstructed signals');
                legend(app.RecoveredBitsAxes, {'Original','Recovered'}, ...
                    'Location','best');
            end

            grid(app.RecoveredBitsAxes, 'on');
            xlabel(app.RecoveredBitsAxes, 'Time (s)');
            app.RecoveredBitsAxes.XColor = [0.15 0.15 0.15];
            app.RecoveredBitsAxes.YColor = [0.15 0.15 0.15];
            app.RecoveredBitsAxes.GridColor = [0.60 0.60 0.60];
            app.RecoveredBitsAxes.GridAlpha = 0.28;
            app.RecoveredBitsAxes.Color = [1 1 1];
            xlim(app.RecoveredBitsAxes, [result.t(1) result.displayEnd]);
        end

        function result = simulateASK(app, snrDb, gainDb)
            fcKHz = app.Param1Slider.Value;
            fc = 1e3*fcKHz;
            Rb = app.Param2Slider.Value;
            A = app.Param3Slider.Value;
            bits = app.SourceBits;

            Fs = max(100e3,40*fc);
            samplesPerBit = max(80,round(Fs/Rb));
            Fs = samplesPerBit*Rb;

            inputWave = repelem(bits,samplesPerBit);
            t = (0:numel(inputWave)-1)/Fs;
            carrier = cos(2*pi*fc*t);
            tx = A*inputWave.*carrier;
            rx = app.applyChannel(tx,snrDb,gainDb,samplesPerBit);

            gainLinear = 10^(gainDb/20);
            product = 2*rx.*carrier;
            recBits = zeros(size(bits));
            decisionValues = zeros(size(bits));

            for k = 1:numel(bits)
                idx = (k-1)*samplesPerBit + (1:samplesPerBit);
                decisionValues(k) = mean(product(idx));
                recBits(k) = decisionValues(k) > gainLinear*A/2;
            end

            baseband = repelem(decisionValues/(gainLinear*A + eps),samplesPerBit);
            bitWave = repelem(recBits,samplesPerBit);

            errors = sum(bits ~= recBits);
            ber = errors/numel(bits);

            result.t = t;
            result.displayEnd = min(t(end),6/Rb);
            result.tx = tx;
            result.rx = rx;
            result.recovered = baseband;
            result.recoveredTitle = 'ASK demodulator output';
            result.bitWave = bitWave;
            result.reference = inputWave;
            result.metric = sprintf('BER = %.4f    Errors = %d / %d', ...
                ber,errors,numel(bits));

            nShow = min(30,numel(bits));
            result.bitsText = sprintf('First %d bits:\nTx: %s\nRx: %s', ...
                nShow,app.bitsToString(bits(1:nShow)), ...
                app.bitsToString(recBits(1:nShow)));

            result.info = sprintf( ...
                'fc = %.2f kHz | Rb = %.0f bit/s | A = %.2f', ...
                fcKHz,Rb,A);
        end

        function result = simulateFSK(app, snrDb, gainDb)
            f1KHz = app.Param1Slider.Value;
            f0KHz = app.Param2Slider.Value;
            f1 = 1e3*f1KHz;
            f0 = 1e3*f0KHz;
            Rb = app.Param3Slider.Value;
            bits = app.SourceBits;

            Fs = max(120e3,40*max(f1,f0));
            samplesPerBit = max(100,round(Fs/Rb));
            Fs = samplesPerBit*Rb;

            nBits = numel(bits);
            frequencyWave = repelem(f0 + (f1-f0)*bits,samplesPerBit);
            phase = 2*pi*cumsum(frequencyWave)/Fs;
            t = (0:numel(frequencyWave)-1)/Fs;
            tx = cos(phase);

            rx = app.applyChannel(tx,snrDb,gainDb,samplesPerBit);
            recBits = zeros(1,nBits);
            metric = zeros(1,nBits);

            for k = 1:nBits
                idx = (k-1)*samplesPerBit + (1:samplesPerBit);
                tk = (0:samplesPerBit-1)/Fs;
                segment = rx(idx);

                c1 = sum(segment.*cos(2*pi*f1*tk));
                s1 = sum(segment.*sin(2*pi*f1*tk));
                c0 = sum(segment.*cos(2*pi*f0*tk));
                s0 = sum(segment.*sin(2*pi*f0*tk));

                e1 = c1^2 + s1^2;
                e0 = c0^2 + s0^2;
                metric(k) = (e1-e0)/(e1+e0+eps);
                recBits(k) = metric(k) > 0;
            end

            recovered = repelem(metric,samplesPerBit);
            bitWave = repelem(recBits,samplesPerBit);

            errors = sum(bits ~= recBits);
            ber = errors/nBits;

            result.t = t;
            result.displayEnd = min(t(end),4/Rb);
            result.tx = tx;
            result.rx = rx;
            result.recovered = recovered;
            result.recoveredTitle = 'FSK detector output';
            result.bitWave = bitWave;
            result.reference = repelem(bits,samplesPerBit);
            result.metric = sprintf('BER = %.4f    Errors = %d / %d', ...
                ber,errors,nBits);

            nShow = min(30,numel(bits));
            result.bitsText = sprintf('First %d bits:\nTx: %s\nRx: %s', ...
                nShow,app.bitsToString(bits(1:nShow)), ...
                app.bitsToString(recBits(1:nShow)));

            result.info = sprintf( ...
                'f1 = %.2f kHz | f0 = %.2f kHz | Rb = %.0f bit/s', ...
                f1KHz,f0KHz,Rb);
        end

        function result = simulatePWM(app, snrDb, gainDb)
            fm = app.Param1Slider.Value;
            fc = app.Param2Slider.Value;
            Am = app.Param3Slider.Value;

            Fs = max(5000,80*fc);
            duration = 1.2;
            t = 0:1/Fs:duration-1/Fs;

            message = Am*sin(2*pi*fm*t);
            normalizedMessage = (message/Am + 1)/2;
            saw = mod(fc*t,1);
            tx = double(normalizedMessage >= saw);

            samplesPerPeriod = max(3,round(Fs/fc));
            rx = app.applyChannel(tx,snrDb,gainDb,samplesPerPeriod);

            gainLinear = 10^(gainDb/20);
            detected = double(rx > gainLinear/2);
            h = ones(1,samplesPerPeriod)/samplesPerPeriod;
            duty = filter(h,1,detected);
            recovered = Am*(2*duty-1);

            errors = sum(tx ~= detected);
            ber = errors/numel(tx);

            result.t = t;
            result.displayEnd = min(t(end),0.25);
            result.tx = tx;
            result.rx = rx;
            result.recovered = recovered;
            result.recoveredTitle = 'PWM reconstructed message';
            result.bitWave = detected;
            result.reference = tx;
            result.metric = sprintf('BER = %.4f    Errors = %d / %d', ...
                ber,errors,numel(tx));

            nShow = min(30,numel(tx));
            result.bitsText = sprintf('First %d samples:\nTx: %s\nRx: %s', ...
                nShow,app.bitsToString(tx(1:nShow)), ...
                app.bitsToString(detected(1:nShow)));
            result.info = sprintf( ...
                'fm = %.1f Hz | PWM carrier = %.1f Hz | Am = %.2f', ...
                fm,fc,Am);
        end

        function result = simulateDM(app, snrDb, gainDb)
            fm = app.Param1Slider.Value;
            fs = round(app.Param2Slider.Value);
            delta = app.Param3Slider.Value;

            duration = 1.2;
            t = 0:1/fs:duration-1/fs;
            message = 0.8*sin(2*pi*fm*t);

            n = numel(message);
            bits = zeros(1,n);
            staircase = zeros(1,n);

            for k = 2:n
                bits(k) = message(k) >= staircase(k-1);
                staircase(k) = staircase(k-1) + delta*(2*bits(k)-1);
            end

            tx = 2*bits-1;
            rx = app.applyChannel(tx, snrDb, gainDb, 1);
            recBits = rx >= 0;

            recovered = zeros(1,n);
            for k = 2:n
                recovered(k) = recovered(k-1) + delta*(2*recBits(k)-1);
            end

            errors = sum(bits ~= recBits);
            ber = errors/numel(bits);

            result.t = t;
            result.displayEnd = min(t(end), 0.25);
            result.tx = tx;
            result.rx = rx;
            result.recovered = recovered;
            result.recoveredTitle = 'DM reconstructed signal';
            result.bitWave = recBits;
            result.reference = bits;
            result.metric = sprintf('BER = %.4f    Errors = %d / %d', ...
                ber,errors,numel(bits));

            nShow = min(30,numel(bits));
            result.bitsText = sprintf('First %d bits:\nTx: %s\nRx: %s', ...
                nShow,app.bitsToString(bits(1:nShow)), ...
                app.bitsToString(recBits(1:nShow)));
            result.info = sprintf( ...
                'fm = %.1f Hz | fs = %d Hz | Step = %.3f', fm, fs, delta);
        end

        function result = simulateCVSD(app, snrDb, gainDb)
            fm = app.Param1Slider.Value;
            fs = round(app.Param2Slider.Value);
            initialStep = app.Param3Slider.Value;

            duration = 1.2;
            t = 0:1/fs:duration-1/fs;
            message = 0.8*sin(2*pi*fm*t);

            minStep = initialStep/4;
            maxStep = initialStep*8;
            n = numel(message);
            bits = zeros(1,n);
            staircase = zeros(1,n);
            step = initialStep;

            for k = 2:n
                bits(k) = message(k) >= staircase(k-1);

                if k >= 4 && bits(k-1)==bits(k-2) && bits(k-2)==bits(k-3)
                    step = min(maxStep, step*1.35);
                else
                    step = max(minStep, step*0.92);
                end

                staircase(k) = staircase(k-1) + step*(2*bits(k)-1);
            end

            tx = 2*bits-1;
            rx = app.applyChannel(tx, snrDb, gainDb, 1);
            recBits = rx >= 0;

            recovered = zeros(1,n);
            step = initialStep;

            for k = 2:n
                if k >= 4 && recBits(k-1)==recBits(k-2) && recBits(k-2)==recBits(k-3)
                    step = min(maxStep, step*1.35);
                else
                    step = max(minStep, step*0.92);
                end

                recovered(k) = recovered(k-1) + step*(2*recBits(k)-1);
            end

            errors = sum(bits ~= recBits);
            ber = errors/numel(bits);

            result.t = t;
            result.displayEnd = min(t(end), 0.25);
            result.tx = tx;
            result.rx = rx;
            result.recovered = recovered;
            result.recoveredTitle = 'CVSD reconstructed signal';
            result.bitWave = recBits;
            result.reference = bits;
            result.metric = sprintf('BER = %.4f    Errors = %d / %d', ...
                ber,errors,numel(bits));

            nShow = min(30,numel(bits));
            result.bitsText = sprintf('First %d bits:\nTx: %s\nRx: %s', ...
                nShow,app.bitsToString(bits(1:nShow)), ...
                app.bitsToString(recBits(1:nShow)));
            result.info = sprintf( ...
                'fm = %.1f Hz | fs = %d Hz | Initial step = %.3f', ...
                fm, fs, initialStep);
        end

        function rx = applyChannel(~, tx, snrDb, gainDb, samplesPerSymbol)
            gainLinear = 10^(gainDb/20);

            gamma = 10^(snrDb/10);
            n = min(samplesPerSymbol, numel(tx));
            symbolEnergy = sum(tx(1:n).^2);
            symbolEnergy = max(symbolEnergy, eps);

            noiseVariance = symbolEnergy/(2*gamma);
            noise = sqrt(noiseVariance)*randn(size(tx));
            rx = gainLinear*tx + noise;
        end

        function txt = bitsToString(~, bits)
            txt = sprintf('%d', bits);
        end

        function styleLabel(~, label)
            label.FontColor = [0.10 0.10 0.10];
            label.FontSize = 13;
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible','off');
            app.UIFigure.Name = 'CommLab v6.1';
            app.UIFigure.Position = [40 40 1510 880];
            app.UIFigure.Color = [0.94 0.94 0.94];

            app.MainGrid = uigridlayout(app.UIFigure,[3 3]);
            app.MainGrid.RowHeight = {72,'1x',42};
            app.MainGrid.ColumnWidth = {'1x','1x','1x'};
            app.MainGrid.Padding = [14 12 14 12];
            app.MainGrid.ColumnSpacing = 12;
            app.MainGrid.RowSpacing = 10;

            app.TitleLabel = uilabel(app.MainGrid);
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = [1 3];
            app.TitleLabel.Text = 'DIGITAL COMMUNICATIONS LAB SIMULATOR';
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 27;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [0.02 0.35 0.62];

            commonRows = {36,36,36,50,36,50,36,'1x',30,135,42,72};

            app.ModPanel = uipanel(app.MainGrid);
            app.ModPanel.Layout.Row = 2;
            app.ModPanel.Layout.Column = 1;
            app.ModPanel.Title = '1. MODULATOR';
            app.ModPanel.FontWeight = 'bold';
            app.ModPanel.ForegroundColor = [0.05 0.25 0.55];

            modGrid = uigridlayout(app.ModPanel,[12 3]);
            modGrid.RowHeight = commonRows;
            modGrid.ColumnWidth = {155,'1x',65};
            modGrid.Padding = [10 8 10 8];
            modGrid.RowSpacing = 5;

            lab = uilabel(modGrid,'Text','Scheme'); app.styleLabel(lab);
            app.SchemeDropDown = uidropdown(modGrid);
            app.SchemeDropDown.Layout.Column = [2 3];
            app.SchemeDropDown.Items = {'ASK','FSK','PWM','CVSD','DM'};
            app.SchemeDropDown.ValueChangedFcn = @(~,e) app.schemeChanged(e);

            lab = uilabel(modGrid,'Text','Input'); app.styleLabel(lab);
            app.InputValueLabel = uilabel(modGrid,'Text','Random bits');
            app.InputValueLabel.Layout.Column = [2 3];
            app.InputValueLabel.HorizontalAlignment = 'left';
            app.InputValueLabel.FontWeight = 'bold';
            app.styleLabel(app.InputValueLabel);

            app.Param1Label = uilabel(modGrid); app.styleLabel(app.Param1Label);
            app.Param1Slider = uislider(modGrid);
            app.Param1Slider.Layout.Column = 2;
            app.Param1ValueLabel = uilabel(modGrid,'HorizontalAlignment','right');
            app.styleLabel(app.Param1ValueLabel);

            app.Param2Label = uilabel(modGrid); app.styleLabel(app.Param2Label);
            app.Param2Slider = uislider(modGrid);
            app.Param2Slider.Layout.Column = 2;
            app.Param2ValueLabel = uilabel(modGrid,'HorizontalAlignment','right');
            app.styleLabel(app.Param2ValueLabel);

            app.Param3Label = uilabel(modGrid); app.styleLabel(app.Param3Label);
            app.Param3Slider = uislider(modGrid);
            app.Param3Slider.Layout.Column = 2;
            app.Param3ValueLabel = uilabel(modGrid,'HorizontalAlignment','right');
            app.styleLabel(app.Param3ValueLabel);

            app.Param1Slider.ValueChangingFcn = @(~,e) app.sliderChanging(e,'p1');
            app.Param2Slider.ValueChangingFcn = @(~,e) app.sliderChanging(e,'p2');
            app.Param3Slider.ValueChangingFcn = @(~,e) app.sliderChanging(e,'p3');
            app.Param1Slider.ValueChangedFcn = @(~,e) app.sliderChanged(e);
            app.Param2Slider.ValueChangedFcn = @(~,e) app.sliderChanged(e);
            app.Param3Slider.ValueChangedFcn = @(~,e) app.sliderChanged(e);

            app.ModAxes = uiaxes(modGrid);
            app.ModAxes.Layout.Row = [8 9];
            app.ModAxes.Layout.Column = [1 3];

            app.InputBitsAxes = uiaxes(modGrid);
            app.InputBitsAxes.Layout.Row = 10;
            app.InputBitsAxes.Layout.Column = [1 3];

            app.ModInfoLabel = uilabel(modGrid);
            app.ModInfoLabel.Layout.Row = 11;
            app.ModInfoLabel.Layout.Column = [1 3];
            app.ModInfoLabel.VerticalAlignment = 'center';
            app.ModInfoLabel.FontColor = [0.10 0.10 0.10];

            buttonGrid = uigridlayout(modGrid,[1 1]);
            buttonGrid.Layout.Row = 12;
            buttonGrid.Layout.Column = [1 3];
            buttonGrid.ColumnWidth = {'1x'};
            buttonGrid.Padding = [0 0 0 0];

            app.NewInputButton = uibutton(buttonGrid,'push','Text','Generate new input');
            app.NewInputButton.Layout.Column = 1;
            app.NewInputButton.ButtonPushedFcn = @(~,e) app.generateNewInput(e);

            app.ChannelPanel = uipanel(app.MainGrid);
            app.ChannelPanel.Layout.Row = 2;
            app.ChannelPanel.Layout.Column = 2;
            app.ChannelPanel.Title = '2. CHANNEL';
            app.ChannelPanel.FontWeight = 'bold';
            app.ChannelPanel.ForegroundColor = [0.55 0.05 0.05];

            channelGrid = uigridlayout(app.ChannelPanel,[12 3]);
            channelGrid.RowHeight = commonRows;
            channelGrid.ColumnWidth = {155,'1x',65};
            channelGrid.Padding = [10 8 10 8];
            channelGrid.RowSpacing = 5;

            lab = uilabel(channelGrid,'Text','Channel model'); app.styleLabel(lab);
            channelValueLabel = uilabel(channelGrid,'Text','AWGN');
            channelValueLabel.Layout.Column = [2 3];
            channelValueLabel.HorizontalAlignment = 'left';
            channelValueLabel.FontWeight = 'bold';
            app.styleLabel(channelValueLabel);

            lab = uilabel(channelGrid,'Text','SNR (dB)'); app.styleLabel(lab);
            app.SNRSlider = uislider(channelGrid,'Limits',[-10 20], ...
                'Value',10,'MajorTicks',[-10 0 10 20]);
            app.SNRSlider.Layout.Column = 2;
            app.SNRValueLabel = uilabel(channelGrid,'HorizontalAlignment','right');
            app.styleLabel(app.SNRValueLabel);

            lab = uilabel(channelGrid,'Text','Gain (dB)'); app.styleLabel(lab);
            app.GainSlider = uislider(channelGrid,'Limits',[-20 10], ...
                'Value',0,'MajorTicks',[-20 0 10]);
            app.GainSlider.Layout.Column = 2;
            app.GainValueLabel = uilabel(channelGrid,'HorizontalAlignment','right');
            app.styleLabel(app.GainValueLabel);

            app.SNRSlider.ValueChangingFcn = @(~,e) app.sliderChanging(e,'snr');
            app.GainSlider.ValueChangingFcn = @(~,e) app.sliderChanging(e,'gain');
            app.SNRSlider.ValueChangedFcn = @(~,e) app.sliderChanged(e);
            app.GainSlider.ValueChangedFcn = @(~,e) app.sliderChanged(e);

            app.ChannelAxes = uiaxes(channelGrid);
            app.ChannelAxes.Layout.Row = [8 9];
            app.ChannelAxes.Layout.Column = [1 3];

            app.ChannelInfoLabel = uilabel(channelGrid);
            app.ChannelInfoLabel.Layout.Row = 10;
            app.ChannelInfoLabel.Layout.Column = [1 3];
            app.ChannelInfoLabel.VerticalAlignment = 'top';
            app.ChannelInfoLabel.FontColor = [0.10 0.10 0.10];

            app.DemodPanel = uipanel(app.MainGrid);
            app.DemodPanel.Layout.Row = 2;
            app.DemodPanel.Layout.Column = 3;
            app.DemodPanel.Title = '3. DEMODULATOR';
            app.DemodPanel.FontWeight = 'bold';
            app.DemodPanel.ForegroundColor = [0.05 0.40 0.08];

            demodGrid = uigridlayout(app.DemodPanel,[12 1]);
            demodGrid.RowHeight = commonRows;
            demodGrid.Padding = [10 8 10 8];
            demodGrid.RowSpacing = 5;

            automaticLabel = uilabel(demodGrid, ...
                'Text','Automatic matching demodulator');
            automaticLabel.FontWeight = 'bold';
            app.styleLabel(automaticLabel);

            app.DemodAxes = uiaxes(demodGrid);
            app.DemodAxes.Layout.Row = [8 9];

            app.RecoveredBitsAxes = uiaxes(demodGrid);
            app.RecoveredBitsAxes.Layout.Row = 10;

            app.MetricLabel = uilabel(demodGrid);
            app.MetricLabel.Layout.Row = 11;
            app.MetricLabel.FontWeight = 'bold';
            app.MetricLabel.FontSize = 15;
            app.MetricLabel.FontColor = [0.05 0.45 0.08];

            app.BitsLabel = uilabel(demodGrid);
            app.BitsLabel.Layout.Row = 12;
            app.BitsLabel.FontName = 'Courier New';
            app.BitsLabel.FontSize = 11;
            app.BitsLabel.FontColor = [0.10 0.10 0.10];
            app.BitsLabel.VerticalAlignment = 'top';

            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = [1 3];
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontColor = [0.10 0.10 0.10];
            app.StatusLabel.FontWeight = 'bold';

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = CommLabAppV6_1
            app.createComponents();
            registerApp(app,app.UIFigure);
            runStartupFcn(app,@startupFcn);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
