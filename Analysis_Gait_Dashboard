function varargout = AnalysisGaitGUI_new(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalysisGaitGUI_new_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalysisGaitGUI_new_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%% --- Executes just before AnalysisGaitGUI_new is made visible.
function AnalysisGaitGUI_new_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
% Initialize table columns
set(handles.gyroTable, 'ColumnName', {'Time', 'X-Right', 'Y-Right', 'Z-Right', 'X-Left', 'Y-Left', 'Z-Left'});
set(handles.accTable, 'ColumnName', {'Time', 'X-Right', 'Y-Right', 'Z-Right', 'X-Left', 'Y-Left', 'Z-Left'});
% Initialize panel visibility
handles.allPanels = [handles.uipanel1, handles.uipanel2];

% Set initial state (Gyroscope view)
set(handles.radiobutton6, 'Value', 1);
set(handles.radiobutton7, 'Value', 0);
updatePanelVisibility(handles, 'gyro');

% Initialize text display
set(handles.text2, 'String', 'Status: Ready');

% Initialize axes
handles.axes = [handles.axes1, handles.axes2, handles.axes3, ...
               handles.axes22, handles.axes23, handles.axes24];

guidata(hObject, handles);
% --- Outputs from this function are returned to the command line.
function varargout = AnalysisGaitGUI_new_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
%% --- Executes on button press in pushbuttonstart.
function pushbuttonstart_Callback(hObject, eventdata, handles)
try
    % Initialize arduino connection and data collection
    arduino = serialport("COM8", 115200);
    data = {};
    counter = 1;
    R_count = 0;
    L_count = 0;
    target_count = 50;

    % Update status
    set(handles.text2, 'String', 'Status: Collecting data...');
    
    % Collect data
    while (R_count < target_count) || (L_count < target_count)
        dataimu = fscanf(arduino,'%lu, %c%.2f, %.2f, %.2f, %.2f, %.2f, %.2f\n');
        
        if startsWith(dataimu, 'R')
            if R_count < target_count
                data{counter} = dataimu;
                R_count = R_count + 1;
                counter = counter + 1;
            end
        elseif startsWith(dataimu, 'L')
            if L_count < target_count
                data{counter} = dataimu;
                L_count = L_count + 1;
                counter = counter + 1;
            end
        end
        
        % Update status with count
        set(handles.text2, 'String', sprintf('Status: Collecting... R: %d, L: %d', R_count, L_count));
        drawnow;
    end

    % Cleanup arduino
    clear arduino;

    % Process data
    data_str = string(data);
    data_str = data_str';

    % Separate R and L data
    data_R = data_str(startsWith(data_str, 'R'));
    data_L = data_str(startsWith(data_str, 'L'));

    % Clean newline characters
    data_R = deblank(regexprep(data_R, '[\n\r↵]', ''));
    data_L = deblank(regexprep(data_L, '[\n\r↵]', ''));

    % Split and convert data
    a = split(data_R, ","|"R");
    b = split(data_L, ","|"L");
    a_numeric = str2double(a);
    b_numeric = str2double(b);

    % Split Acc and Gyro
    AccR = a_numeric(:, 2:4);
    GyroR = a_numeric(:, 5:7);
    AccL = b_numeric(:, 2:4);
    GyroL = b_numeric(:, 5:7);

    % Combine data
    Acc_2titik = [AccR, AccL];
    Gyro_2titik = [GyroR, GyroL];

    % Create time vector (assuming 100Hz sampling rate)
    timeVector = (1:size(Acc_2titik, 1))' / 100;

    % Update tables
    gyroTableData = [timeVector, Gyro_2titik];
    accTableData = [timeVector, Acc_2titik];
    set(handles.gyroTable, 'Data', gyroTableData);
    set(handles.accTable, 'Data', accTableData);

    set(handles.text2, 'String', 'Status: Data collection complete');

catch ME
    set(handles.text2, 'String', ['Status: Error - ' ME.message]);
    if exist('arduino', 'var')
        clear arduino;
    end
end


% --- Executes on button press in pushbuttonload.
function pushbuttonload_Callback(hObject, eventdata, handles)
try
    % Get data from tables
    gyroData = get(handles.gyroTable, 'Data');
    accData = get(handles.accTable, 'Data');
    
    % Extract data
    gyro_1_smoothed = gyroData(:, 2:4);  % Right foot gyro
    gyro_2_smoothed = gyroData(:, 5:7);  % Left foot gyro
    acc_1_smoothed = accData(:, 2:4);    % Right foot acc
    acc_2_smoothed = accData(:, 5:7);    % Left foot acc
    
    % GYROSCOPE DATA PROCESSING AND VISUALIZATION
    % Calculate peak values for each axis
    peak_right_x_gyro = max(gyro_1_smoothed(:,1));
    peak_left_x_gyro = max(gyro_2_smoothed(:,1));
    peak_right_y_gyro = max(gyro_1_smoothed(:,2));
    peak_left_y_gyro = max(gyro_2_smoothed(:,2));
    peak_right_z_gyro = max(gyro_1_smoothed(:,3));
    peak_left_z_gyro = max(gyro_2_smoothed(:,3));

    % Calculate mean values for each axis
    mean_right_x_gyro = mean(gyro_1_smoothed(:,1));
    mean_left_x_gyro = mean(gyro_2_smoothed(:,1));
    mean_right_y_gyro = mean(gyro_1_smoothed(:,2));
    mean_left_y_gyro = mean(gyro_2_smoothed(:,2));
    mean_right_z_gyro = mean(gyro_1_smoothed(:,3));
    mean_left_z_gyro = mean(gyro_2_smoothed(:,3));

    % Calculate SI using peak values
    SI_peak_x_gyro = abs(peak_right_x_gyro - peak_left_x_gyro) / (0.5 * (peak_right_x_gyro + peak_left_x_gyro)) * 100;
    SI_peak_y_gyro = abs(peak_right_y_gyro - peak_left_y_gyro) / (0.5 * (peak_right_y_gyro + peak_left_y_gyro)) * 100;
    SI_peak_z_gyro = abs(peak_right_z_gyro - peak_left_z_gyro) / (0.5 * (peak_right_z_gyro + peak_left_z_gyro)) * 100;

    % Calculate SI using mean values
    SI_mean_x_gyro = abs(mean_right_x_gyro - mean_left_x_gyro) / (0.5 * (mean_right_x_gyro + mean_left_x_gyro)) * 100;
    SI_mean_y_gyro = abs(mean_right_y_gyro - mean_left_y_gyro) / (0.5 * (mean_right_y_gyro + mean_left_y_gyro)) * 100;
    SI_mean_z_gyro = abs(mean_right_z_gyro - mean_left_z_gyro) / (0.5 * (mean_right_z_gyro + mean_left_z_gyro)) * 100;

    handles.gyro_processed.time = gyroData(:,1);
    handles.gyro_processed.right = gyro_1_smoothed;
    handles.gyro_processed.left = gyro_2_smoothed;
    handles.gyro_processed.SI_peak = [SI_peak_x_gyro, SI_peak_y_gyro, SI_peak_z_gyro];
    handles.gyro_processed.SI_mean = [SI_mean_x_gyro, SI_mean_y_gyro, SI_mean_z_gyro];

    % Find peaks for heel strike and toe off
    [~, hs_right] = findpeaks(gyro_1_smoothed(:,3), 'MinPeakHeight', mean(gyro_1_smoothed(:,3)));
    [~, hs_left] = findpeaks(gyro_2_smoothed(:,3), 'MinPeakHeight', mean(gyro_2_smoothed(:,3)));
    [~, to_right] = findpeaks(-gyro_1_smoothed(:,3), 'MinPeakHeight', mean(-gyro_1_smoothed(:,3)));
    [~, to_left] = findpeaks(-gyro_2_smoothed(:,3), 'MinPeakHeight', mean(-gyro_2_smoothed(:,3)));

    % Plot gyroscope data
    % X-axis
    axes(handles.axes1);
    cla;
    plot(gyro_1_smoothed(:,1), 'b-', 'DisplayName', 'Right Foot');
    hold on;
    plot(gyro_2_smoothed(:,1), 'r-', 'DisplayName', 'Left Foot');
    plot(hs_right, gyro_1_smoothed(hs_right,1), 'b^', 'DisplayName', 'Right HS');
    plot(hs_left, gyro_2_smoothed(hs_left,1), 'r^', 'DisplayName', 'Left HS');
    plot(to_right, gyro_1_smoothed(to_right,1), 'bo', 'DisplayName', 'Right TO');
    plot(to_left, gyro_2_smoothed(to_left,1), 'ro', 'DisplayName', 'Left TO');
    title(['X-axis Angular Velocity - SI Peak: ' num2str(SI_peak_x_gyro,'%.2f') '%, SI Mean: ' num2str(SI_mean_x_gyro,'%.2f') '%'], 'FontSize', 7);
    ylabel('Angular Velocity (deg/s)', 'FontSize', 6);
    xlabel('Time (s)', 'FontSize', 6);
    legend;
    grid on;

    % Y-axis
    axes(handles.axes2);
    cla;
    plot(gyro_1_smoothed(:,2), 'b-', 'DisplayName', 'Right Foot');
    hold on;
    plot(gyro_2_smoothed(:,2), 'r-', 'DisplayName', 'Left Foot');
    plot(hs_right, gyro_1_smoothed(hs_right,2), 'b^', 'DisplayName', 'Right HS');
    plot(hs_left, gyro_2_smoothed(hs_left,2), 'r^', 'DisplayName', 'Left HS');
    plot(to_right, gyro_1_smoothed(to_right,2), 'bo', 'DisplayName', 'Right TO');
    plot(to_left, gyro_2_smoothed(to_left,2), 'ro', 'DisplayName', 'Left TO');
    title(['Y-axis Angular Velocity - SI Peak: ' num2str(SI_peak_y_gyro,'%.2f') '%, SI Mean: ' num2str(SI_mean_y_gyro,'%.2f') '%'], 'FontSize', 7);
    ylabel('Angular Velocity (deg/s)', 'FontSize', 6);
    xlabel('Time (s)', 'FontSize', 6);
    legend;
    grid on;

    % Z-axis
    axes(handles.axes3);
    cla;
    plot(gyro_1_smoothed(:,3), 'b-', 'DisplayName', 'Right Foot');
    hold on;
    plot(gyro_2_smoothed(:,3), 'r-', 'DisplayName', 'Left Foot');
    plot(hs_right, gyro_1_smoothed(hs_right,3), 'b^', 'DisplayName', 'Right HS');
    plot(hs_left, gyro_2_smoothed(hs_left,3), 'r^', 'DisplayName', 'Left HS');
    plot(to_right, gyro_1_smoothed(to_right,3), 'bo', 'DisplayName', 'Right TO');
    plot(to_left, gyro_2_smoothed(to_left,3), 'ro', 'DisplayName', 'Left TO');
    title(['Z-axis Angular Velocity - SI Peak: ' num2str(SI_peak_z_gyro,'%.2f') '%, SI Mean: ' num2str(SI_mean_z_gyro,'%.2f') '%'], 'FontSize', 7);
    ylabel('Angular Velocity (deg/s)', 'FontSize', 6);
    xlabel('Time (s)', 'FontSize', 6);
    legend;
    grid on;

    % ACCELEROMETER DATA PROCESSING AND VISUALIZATION
    % Calculate peak values for each axis
    peak_right_x_acc = max(acc_1_smoothed(:,1));
    peak_left_x_acc = max(acc_2_smoothed(:,1));
    peak_right_y_acc = max(acc_1_smoothed(:,2));
    peak_left_y_acc = max(acc_2_smoothed(:,2));
    peak_right_z_acc = max(acc_1_smoothed(:,3));
    peak_left_z_acc = max(acc_2_smoothed(:,3));

    % Calculate mean values for each axis
    mean_right_x_acc = mean(acc_1_smoothed(:,1));
    mean_left_x_acc = mean(acc_2_smoothed(:,1));
    mean_right_y_acc = mean(acc_1_smoothed(:,2));
    mean_left_y_acc = mean(acc_2_smoothed(:,2));
    mean_right_z_acc = mean(acc_1_smoothed(:,3));
    mean_left_z_acc = mean(acc_2_smoothed(:,3));

    % Calculate SI using peak values
    SI_peak_x_acc = abs(peak_right_x_acc - peak_left_x_acc) / (0.5 * (peak_right_x_acc + peak_left_x_acc)) * 100;
    SI_peak_y_acc = abs(peak_right_y_acc - peak_left_y_acc) / (0.5 * (peak_right_y_acc + peak_left_y_acc)) * 100;
    SI_peak_z_acc = abs(peak_right_z_acc - peak_left_z_acc) / (0.5 * (peak_right_z_acc + peak_left_z_acc)) * 100;

    % Calculate SI using mean values
    SI_mean_x_acc = abs(mean_right_x_acc - mean_left_x_acc) / (0.5 * (mean_right_x_acc + mean_left_x_acc)) * 100;
    SI_mean_y_acc = abs(mean_right_y_acc - mean_left_y_acc) / (0.5 * (mean_right_y_acc + mean_left_y_acc)) * 100;
    SI_mean_z_acc = abs(mean_right_z_acc - mean_left_z_acc) / (0.5 * (mean_right_z_acc + mean_left_z_acc)) * 100;

    handles.acc_processed.time = accData(:,1);
    handles.acc_processed.right = acc_1_smoothed;
    handles.acc_processed.left = acc_2_smoothed;
    handles.acc_processed.SI_peak = [SI_peak_x_acc, SI_peak_y_acc, SI_peak_z_acc];
    handles.acc_processed.SI_mean = [SI_mean_x_acc, SI_mean_y_acc, SI_mean_z_acc];
    
    % Save the handles structure
    guidata(hObject, handles);

    % Find peaks for heel strike and toe off
    [~, hs_right_acc] = findpeaks(acc_1_smoothed(:,3), 'MinPeakHeight', mean(acc_1_smoothed(:,3)));
    [~, hs_left_acc] = findpeaks(acc_2_smoothed(:,3), 'MinPeakHeight', mean(acc_2_smoothed(:,3)));
    [~, to_right_acc] = findpeaks(-acc_1_smoothed(:,3), 'MinPeakHeight', mean(-acc_1_smoothed(:,3)));
    [~, to_left_acc] = findpeaks(-acc_2_smoothed(:,3), 'MinPeakHeight', mean(-acc_2_smoothed(:,3)));

    % Plot accelerometer data
    % X-axis
    axes(handles.axes22);
    cla;
    plot(acc_1_smoothed(:,1), 'b-', 'DisplayName', 'Right Foot');
    hold on;
    plot(acc_2_smoothed(:,1), 'r-', 'DisplayName', 'Left Foot');
    plot(hs_right_acc, acc_1_smoothed(hs_right_acc,1), 'b^', 'DisplayName', 'Right HS');
    plot(hs_left_acc, acc_2_smoothed(hs_left_acc,1), 'r^', 'DisplayName', 'Left HS');
    plot(to_right_acc, acc_1_smoothed(to_right_acc,1), 'bo', 'DisplayName', 'Right TO');
    plot(to_left_acc, acc_2_smoothed(to_left_acc,1), 'ro', 'DisplayName', 'Left TO');
    title(['X-axis Acceleration - SI Peak: ' num2str(SI_peak_x_acc,'%.2f') '%, SI Mean: ' num2str(SI_mean_x_acc,'%.2f') '%'], 'FontSize', 7);
    ylabel('Acceleration (m/s^2)', 'FontSize', 6);
    xlabel('Time (s)', 'FontSize', 6);
    legend;
    grid on;

    % Y-axis
    axes(handles.axes23);
    cla;
    plot(acc_1_smoothed(:,2), 'b-', 'DisplayName', 'Right Foot');
    hold on;
    plot(acc_2_smoothed(:,2), 'r-', 'DisplayName', 'Left Foot');
    plot(hs_right_acc, acc_1_smoothed(hs_right_acc,2), 'b^', 'DisplayName', 'Right HS');
    plot(hs_left_acc, acc_2_smoothed(hs_left_acc,2), 'r^', 'DisplayName', 'Left HS');
    plot(to_right_acc, acc_1_smoothed(to_right_acc,2), 'bo', 'DisplayName', 'Right TO');
    plot(to_left_acc, acc_2_smoothed(to_left_acc,2), 'ro', 'DisplayName', 'Left TO');
    title(['Y-axis Acceleration - SI Peak: ' num2str(SI_peak_y_acc,'%.2f') '%, SI Mean: ' num2str(SI_mean_y_acc,'%.2f') '%'], 'FontSize', 7);
    ylabel('Acceleration (m/s^2)', 'FontSize', 6);
    xlabel('Time (s)', 'FontSize', 6);
    legend;
    grid on;

    % Z-axis
    axes(handles.axes24);
    cla;
    plot(acc_1_smoothed(:,3), 'b-', 'DisplayName', 'Right Foot');
    hold on;
    plot(acc_2_smoothed(:,3), 'r-', 'DisplayName', 'Left Foot');
    plot(hs_right_acc, acc_1_smoothed(hs_right_acc,3), 'b^', 'DisplayName', 'Right HS');
    plot(hs_left_acc, acc_2_smoothed(hs_left_acc,3), 'r^', 'DisplayName', 'Left HS');
    plot(to_right_acc, acc_1_smoothed(to_right_acc,3), 'bo', 'DisplayName', 'Right TO');
    plot(to_left_acc, acc_2_smoothed(to_left_acc,3), 'ro', 'DisplayName', 'Left TO');
    title(['Z-axis Acceleration - SI Peak: ' num2str(SI_peak_z_acc,'%.2f') '%, SI Mean: ' num2str(SI_mean_z_acc,'%.2f') '%'], 'FontSize', 7);
    ylabel('Acceleration (m/s^2)', 'FontSize', 6);
    xlabel('Time (s)', 'FontSize', 6);
    legend;
    grid on;

    % Update status
    set(handles.text2, 'String', 'Status: Data visualization complete');
catch ME
    set(handles.text2, 'String', ['Status: Error - ' ME.message]);
end


% --- Executes on button press in pushbuttonreset.
function pushbuttonreset_Callback(~, eventdata, handles)
try
    % Clear all tables
    set(handles.gyroTable, 'Data', []);
    set(handles.accTable, 'Data', []);
    
    % Clear all axes
    for ax = [handles.axes1, handles.axes2, handles.axes3, ...
             handles.axes22, handles.axes23, handles.axes24]
        cla(ax);
        title(ax, '');
        xlabel(ax, '');
        ylabel(ax, '');
        legend(ax, 'off');
    end
    
    % Clear stored data from handles
    if isfield(handles, 'gyro_processed')
        handles = rmfield(handles, 'gyro_processed');
    end
    if isfield(handles, 'acc_processed')
        handles = rmfield(handles, 'acc_processed');
    end
    if isfield(handles, 'gyro_raw')
        handles = rmfield(handles, 'gyro_raw');
    end
    if isfield(handles, 'acc_raw')
        handles = rmfield(handles, 'acc_raw');
    end
    
    % Update status
    set(handles.text2, 'String', 'Status: Data reset complete');
    
    % Save the updated handles structure
    guidata(hObject, handles);
    
catch ME
    set(handles.text2, 'String', ['Status: Error during reset - ' ME.message]);
end

% --- Executes on button press in pushbuttonexportGyro.
function pushbuttonexportGyro_Callback(hObject, eventdata, handles)
try
    if ~isfield(handles, 'gyro_processed')
        set(handles.text2, 'String', 'Status: No processed gyroscope data to export');
        return;
    end
    
    [filename, pathname] = uiputfile('*.csv', 'Save Gyroscope Data');
    if filename == 0
        return;
    end
    
    % Create a table with all the gyro data
    time = handles.gyro_processed.time;
    right_xyz = handles.gyro_processed.right;
    left_xyz = handles.gyro_processed.left;
    
    data_table = array2table([time, right_xyz, left_xyz], ...
        'VariableNames', {'Time', 'Right_X', 'Right_Y', 'Right_Z', ...
                         'Left_X', 'Left_Y', 'Left_Z'});
    
    % Write the table to CSV
    writetable(data_table, fullfile(pathname, filename));
    set(handles.text2, 'String', 'Status: Gyroscope data exported successfully');
catch ME
    set(handles.text2, 'String', ['Status: Error exporting gyro data: ' ME.message]);
end


% --- Executes on button press in pushbuttonexportAcc.
function pushbuttonexportAcc_Callback(hObject, eventdata, handles)
try
    if ~isfield(handles, 'acc_processed')
        set(handles.text2, 'String', 'Status: No processed accelerometer data to export');
        return;
    end
    
    [filename, pathname] = uiputfile('*.csv', 'Save Accelerometer Data');
    if filename == 0
        return;
    end
    
    % Create a table with all the accelerometer data
    time = handles.acc_processed.time;
    right_xyz = handles.acc_processed.right;
    left_xyz = handles.acc_processed.left;
    
    data_table = array2table([time, right_xyz, left_xyz], ...
        'VariableNames', {'Time', 'Right_X', 'Right_Y', 'Right_Z', ...
                         'Left_X', 'Left_Y', 'Left_Z'});
    
    % Write the table to CSV
    writetable(data_table, fullfile(pathname, filename));
    set(handles.text2, 'String', 'Status: Accelerometer data exported successfully');
catch ME
    set(handles.text2, 'String', ['Status: Error exporting accelerometer data: ' ME.message]);
end
% --- Executes on button press in radiobutton6.
function radiobutton6_Callback(hObject, eventdata, handles)
if get(hObject, 'Value')
    set(handles.radiobutton7, 'Value', 0);
    updatePanelVisibility(handles, 'gyro');
    if isfield(handles, 'rawData')
        updateGyroPlots(handles);
    end
end
% --- Executes on button press in radiobutton7.
function radiobutton7_Callback(hObject, eventdata, handles)
if get(hObject, 'Value')
    set(handles.radiobutton6, 'Value', 0);
    updatePanelVisibility(handles, 'acc');
    if isfield(handles, 'rawData')
        updateAccPlots(handles);
    end
end

% --- Helper function to update panel visibility
function updatePanelVisibility(handles, mode)
if strcmp(mode, 'gyro')
    set(handles.uipanel1, 'Visible', 'on');
    set(handles.uipanel2, 'Visible', 'off');
else
    set(handles.uipanel1, 'Visible', 'off');
    set(handles.uipanel2, 'Visible', 'on');
end
