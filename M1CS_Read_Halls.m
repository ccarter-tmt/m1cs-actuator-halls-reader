% M1CS_Read_Halls.m
%
% Author: Chris Carter
% Email: ccarter@tmt.org
% Revision Date: 20th September 2022
% Version: 1.1
%
% VERSION NOTES:
%
% V1.0 - Reads M1CS Actuator Hall Sensor board voltage outputs and computes
% position displacement. Plots live curves of Hall output voltages and
% position displacement.
%
% V1.1 - Acquires only the number of samples defined by the 'nsamples'
% variable. At termination, the data, as presented in the generated
% Figures, are automatically saved to a file.
%
% INSTALLATION NOTES:
%
% This script requires the LabJack LJM Library which, amongst other things,
% enables communication between MATLAB and the LabJack T4 data acquisition
% unit.
%
% The LabJack LJM Library is introduced here: https://labjack.com/ljm
% The MATLAB LJM Library is available here: https://labjack.com/support/software/examples/ljm/matlab
%
% The MATLAB LJM Library should be unpacked and stored in a location on the
% machine running the script, and added to the MATLAB PATH.
%
% Script has been shown to work with a LabJack T4 and MATLAB Version
% 9.13.0.1967605 (R2022b) Prerelease.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up the MATLAB environment

clc         % Clear the command window

clear all   % Clear previous environment variables and functions
close all;  % Close previous Figures

% Definitions

% From MMCs position calculation recipe

k = 10/1.95;    % Units: mm
V_0 = 1.65;     % Units: Volts

% Some variable declarations

nsamples = 2000;    % Number of samples to record
count = 0;
time = [0];

AIN0_vector = [0];
AIN1_vector = [0];

POS_vector = [0];

% Figure 1: Analogue input voltages from Hall Sensors on target board

f(1) = figure(1);
p = plot (time, AIN0_vector, time, AIN1_vector);

ylim([0 4]);
xlabel('Sample No.');
ylabel('AINx (Volts)');
title('Analogue Hall Voltages');
legend('AIN0', 'AIN1');
grid

p(1).XDataSource = 'time';
p(1).YDataSource = 'AIN0_vector';

p(2).XDataSource = 'time';
p(2).YDataSource = 'AIN1_vector';

% Figure 2: Derived position computed from MMC recipe

f(2) = figure(2);
q = plot(time, POS_vector);

ylim([-25 25]);
xlabel('Sample No.');
ylabel('Position (mm)');
title('Derived Position');
legend('Position (mm)');
grid

q(1).XDataSource = 'time';
q(1).YDataSource = 'POS_vector';

% Make the LJM .NET assembly visible

ljmAsm = NET.addAssembly('LabJack.LJM');

% Creating an object to nested class LabJack.LJM.CONSTANTS

t = ljmAsm.AssemblyHandle.GetType('LabJack.LJM+CONSTANTS');
LJM_CONSTANTS = System.Activator.CreateInstance(t);

handle = 0;

try
    % Open any LabJack device, using any connection, with any identifier

    [ljmError, handle] = LabJack.LJM.OpenS('ANY', 'ANY', 'ANY', handle);
    showDeviceInfo(handle);

    % Set up and call eReadName() to read the Analogue Input(s)

        for loop = 1:nsamples

        [ljmError, AIN0_val] = LabJack.LJM.eReadName(handle, 'AIN0', 0);
        [ljmError, AIN1_val] = LabJack.LJM.eReadName(handle, 'AIN1', 0);

        count = count + 1;
        time(count) = count;

        AIN0_vector(count) = AIN0_val;
        AIN1_vector(count) = AIN1_val;

        % Transfer analogue values from T4 into variables named more
        % consistently with MMC's position calculation recipe

        V_1 = AIN0_val;
        V_2 = AIN1_val;

        % Calculate position in millimetres

        POS_vector(count) = k * (atan(((V_2 - V_0) / (V_1 - V_0)) ...
            + (pi / 4)));

        % Update the data on both plots

        refreshdata(p);
        refreshdata(q);
        drawnow;

        end

        % Save Figures to a file for later review & circulation

        savefig(f, 'Hall_sensor_figures.fig');

catch e
    showErrorMessage(e)
    LabJack.LJM.CloseAll();
    return
end

try
    % Close handle to LabJack device

    LabJack.LJM.Close(handle);
catch e
    showErrorMessage(e)
end

% End of file