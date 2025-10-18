clear all;
close all;
arduino = serialport("COM8", 115200);
data = {};
counter = 1;
R_count = 0;
L_count = 0;
target_count = 50; 

try
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
        
        fprintf('R count: %d, L count: %d\n', R_count, L_count);
        
        if (R_count >= target_count) && (L_count >= target_count)
            break;
        end
    end
catch ME
    % Error handling
    disp('Data collection stopped');
    disp(ME.message);
end

clear arduino;

save('data_imu.mat', 'data');
disp('Data saved to data_imu.mat');
fprintf('Final counts - R: %d, L: %d\n', R_count, L_count);
% Convert menjadi matrix
data_str = string(data);

% Transpose
data_str = data_str';

data_R = data_str(startsWith(data_str, 'R'));
data_L = data_str(startsWith(data_str, 'L'));

data_R = deblank(regexprep(data_R, '[\n\r↵]', ''));
data_L = deblank(regexprep(data_L, '[\n\r↵]', ''));

% Split data dengan menghilangkan semua karakter newline
a = split(data_R, ","|"R");
b = split(data_L, ","|"L");

% Membersihkan empty strings yang mungkin tersisa
a_numeric = str2double(a);
b_numeric = str2double(b);  % Mengonversi elemen ke-2 sampai akhir untuk data kaki kiri

%% SPLIT ACC DAN GYRO 

AccR = a_numeric(:, 2:4);
GyroR = a_numeric(:, 5:7);

AccL = b_numeric(:, 2:4);
GyroL = b_numeric(:, 5:7);

Acc_2titik = [AccR, AccL];
%satukan GyroR dan GyroL menjadi satu file Gyro_2titik (matrix 500x6)
Gyro_2titik = [GyroR, GyroL]

save('Acc_2titik.mat', 'Acc_2titik');
save('Gyro_2titik.mat', 'Gyro_2titik');

%% FIlter AHRS dan Plot Grafik
ld1 = load("Acc_2titik.mat");
ld2 = load("Gyro_2titik.mat");

%whos('-file', 'Acc_2titik.mat');
%whos('-file', 'Gyro_2titik.mat');

acc = ld1.Acc_2titik;
gyro = ld2.Gyro_2titik;

%pp = poseplot;

Fs = 100; % Hz

% Ambil data akselerometer untuk sensor 1 (X1, Y1, Z1)
acc_1 = acc(:, 1:3);  % Kolom 1, 2, 3 untuk sensor 1

% Ambil data akselerometer untuk sensor 2 (X2, Y2, Z2)
acc_2 = acc(:, 4:6);  % Kolom 4, 5, 6 untuk sensor 2

% Ambil data giroskop (asumsi formatnya sama)
gyro_1 = gyro(:, 1:3);  % Kolom 1, 2, 3 untuk sensor 1 (giroskop)
gyro_2 = gyro(:, 4:6);  % Kolom 4, 5, 6 untuk sensor 2 (giroskop)

%% IMUOrientation dengan dua set akselerometer dan giroskop
ifilt = imufilter(SampleRate=Fs);  % Gunakan Fs yang sudah didefinisikan
for ii = 1:size(acc, 1)
    % Proses data set pertama (titik 1) untuk sensor 1 dan giroskop 1
    qimu_1 = ifilt(acc_1(ii,:), gyro_1(ii,:));
    %set(pp, "Orientation", qimu_1);  % Update orientasi dengan set pertama
    drawnow limitrate;

    % Proses data set kedua (titik 2) untuk sensor 2 dan giroskop 2
    qimu_2 = ifilt(acc_2(ii,:), gyro_2(ii,:));
    %set(pp, "Orientation", qimu_2);  % Update orientasi dengan set kedua
    drawnow limitrate;
end

% Smoothing data
windowSize = 20;
gyro_1_smoothed = movmean(gyro_1, windowSize);  % Kaki kanan
gyro_2_smoothed = movmean(gyro_2, windowSize);  % Kaki kiri
acc_1_smoothed = movmean(acc_1, windowSize);  % Kaki kanan
acc_2_smoothed = movmean(acc_2, windowSize);  % Kaki kiri

% Gabungkan Data yang Sudah Di-smoothing
% Menggabungkan data akselerometer dan giroskop yang sudah di-smoothing
smoothed_acc = [acc_1_smoothed, acc_2_smoothed];  % [X1, Y1, Z1, X2, Y2, Z2]
smoothed_gyro = [gyro_1_smoothed, gyro_2_smoothed];  % [X1, Y1, Z1, X2, Y2, Z2]

% Buat Tabel dari Data yang Sudah Di-smoothing
% Membuat tabel dari data akselerometer
acc_table = array2table(smoothed_acc, 'VariableNames', {'X1_acc', 'Y1_acc', 'Z1_acc', 'X2_acc', 'Y2_acc', 'Z2_acc'});

% Membuat tabel dari data giroskop
gyro_table = array2table(smoothed_gyro, 'VariableNames', {'X1_gyro', 'Y1_gyro', 'Z1_gyro', 'X2_gyro', 'Y2_gyro', 'Z2_gyro'});

% PLOT GRAFIK ANGULAR VELOCITY
num_samples = size(gyro, 1); 
time = (0:num_samples-1) / Fs;

% Mendapatkan ranges data
ranges_1 = [
    max(gyro_1_smoothed(:,1)) - min(gyro_1_smoothed(:,1)),  % Range X
    max(gyro_1_smoothed(:,2)) - min(gyro_1_smoothed(:,2)),  % Range Y
    max(gyro_1_smoothed(:,3)) - min(gyro_1_smoothed(:,3))   % Range Z
];

ranges_2 = [
    max(gyro_2_smoothed(:,1)) - min(gyro_2_smoothed(:,1)),  % Range X
    max(gyro_2_smoothed(:,2)) - min(gyro_2_smoothed(:,2)),  % Range Y
    max(gyro_2_smoothed(:,3)) - min(gyro_2_smoothed(:,3))   % Range Z
];

% Print data ranges
fprintf('Gyro 1 ranges:\n');
fprintf('X: %.2f to %.2f (range: %.2f)\n', min(gyro_1_smoothed(:,1)), max(gyro_1_smoothed(:,1)), ranges_1(1));
fprintf('Y: %.2f to %.2f (range: %.2f)\n', min(gyro_1_smoothed(:,2)), max(gyro_1_smoothed(:,2)), ranges_1(2));
fprintf('Z: %.2f to %.2f (range: %.2f)\n', min(gyro_1_smoothed(:,3)), max(gyro_1_smoothed(:,3)), ranges_1(3));
fprintf('\nGyro 2 ranges:\n');
fprintf('X: %.2f to %.2f (range: %.2f)\n', min(gyro_2_smoothed(:,1)), max(gyro_2_smoothed(:,1)), ranges_2(1));
fprintf('Y: %.2f to %.2f (range: %.2f)\n', min(gyro_2_smoothed(:,2)), max(gyro_2_smoothed(:,2)), ranges_2(2));
fprintf('Z: %.2f to %.2f (range: %.2f)\n', min(gyro_2_smoothed(:,3)), max(gyro_2_smoothed(:,3)), ranges_2(3));

% Parameter calculation loop:
for axis = 1:3
    range = max(ranges_1(axis), ranges_2(axis));
    
    % Threshold untuk peak (Heel Strike) - 1% dari range
    minPeakHeight(axis) = 0.01 * range;
    
    % Threshold untuk valley (Toe Off) 
    minValleyHeight(axis) = 0.005 * range; % Setengah dari peak threshold
    
    % Add minimum threshold
    if minPeakHeight(axis) < 0.001
        minPeakHeight(axis) = 0.001;
    end
    if minValleyHeight(axis) < 0.0005 % Lebih rendah untuk valley
        minValleyHeight(axis) = 0.0005;
    end
    
    % Calculate minimum distances
    suggested_distance = round(Fs * 0.3); % 0.3 seconds
    minPeakDistance(axis) = min(suggested_distance, num_samples/2);
    minValleyDistance(axis) = minPeakDistance(axis);
end

% [bagian perhitungan SI tetap sama...]

% Heel Strike detection (peaks) untuk sensor 1
[pks1_x, locs1_x] = findpeaks(gyro_1_smoothed(:,1), ...
    'MinPeakHeight', minPeakHeight(1), ...
    'MinPeakDistance', minPeakDistance(1));
[pks1_y, locs1_y] = findpeaks(gyro_1_smoothed(:,2), ...
    'MinPeakHeight', minPeakHeight(2), ...
    'MinPeakDistance', minPeakDistance(2));
[pks1_z, locs1_z] = findpeaks(gyro_1_smoothed(:,3), ...
    'MinPeakHeight', minPeakHeight(3), ...
    'MinPeakDistance', minPeakDistance(3));

% Toe Off detection (valleys) untuk sensor 1 - dengan threshold yang disesuaikan
[valleys1_x, locs_valleys1_x] = findpeaks(-gyro_1_smoothed(:,1), ...
    'MinPeakHeight', minValleyHeight(1), ...
    'MinPeakDistance', minValleyDistance(1));
[valleys1_y, locs_valleys1_y] = findpeaks(-gyro_1_smoothed(:,2), ...
    'MinPeakHeight', minValleyHeight(2), ...
    'MinPeakDistance', minValleyDistance(2));
[valleys1_z, locs_valleys1_z] = findpeaks(-gyro_1_smoothed(:,3), ...
    'MinPeakHeight', minValleyHeight(3), ...
    'MinPeakDistance', minValleyDistance(3));

% Heel Strike detection (peaks) untuk sensor 2
[pks2_x, locs2_x] = findpeaks(gyro_2_smoothed(:,1), ...
    'MinPeakHeight', minPeakHeight(1), ...
    'MinPeakDistance', minPeakDistance(1));
[pks2_y, locs2_y] = findpeaks(gyro_2_smoothed(:,2), ...
    'MinPeakHeight', minPeakHeight(2), ...
    'MinPeakDistance', minPeakDistance(2));
[pks2_z, locs2_z] = findpeaks(gyro_2_smoothed(:,3), ...
    'MinPeakHeight', minPeakHeight(3), ...
    'MinPeakDistance', minPeakDistance(3));

% Toe Off detection (valleys) untuk sensor 2 - dengan threshold yang disesuaikan
[valleys2_x, locs_valleys2_x] = findpeaks(-gyro_2_smoothed(:,1), ...
    'MinPeakHeight', minValleyHeight(1), ...
    'MinPeakDistance', minValleyDistance(1));
[valleys2_y, locs_valleys2_y] = findpeaks(-gyro_2_smoothed(:,2), ...
    'MinPeakHeight', minValleyHeight(2), ...
    'MinPeakDistance', minValleyDistance(2));
[valleys2_z, locs_valleys2_z] = findpeaks(-gyro_2_smoothed(:,3), ...
    'MinPeakHeight', minValleyHeight(3), ...
    'MinPeakDistance', minValleyDistance(3));

% Plotting sumbu X dengan legend yang diperbaiki
figure;
subplot(3,1,1);
plot(time, gyro_1_smoothed(:,1), 'b', 'DisplayName', 'Right Foot Angular Velocity');
hold on;
if ~isempty(locs1_x)
    plot(time(locs1_x), pks1_x, '^b', 'DisplayName', 'Right Heel Strikes');
end
if ~isempty(locs_valleys1_x)
    plot(time(locs_valleys1_x), -valleys1_x, 'ob', 'DisplayName', 'Right Toe Offs');
end
plot(time, gyro_2_smoothed(:,1), 'r', 'DisplayName', 'Left Foot Angular Velocity');
if ~isempty(locs2_x)
    plot(time(locs2_x), pks2_x, '^r', 'DisplayName', 'Left Heel Strikes');
end
if ~isempty(locs_valleys2_x)
    plot(time(locs_valleys2_x), -valleys2_x, 'or', 'DisplayName', 'Left Toe Offs');
end
title(['X-axis Acceleration - SI Peak: ' num2str(SI_peak_x,'%.2f') '%, SI Mean: ' num2str(SI_mean_x,'%.2f') '%']);
xlabel('Time (s)');
ylabel('Angular Velocity (rad/s)');
legend('show');

% Plotting sumbu Y dengan legend yang diperbaiki
subplot(3,1,2);
plot(time, gyro_1_smoothed(:,2), 'b', 'DisplayName', 'Right Foot Angular Velocity');
hold on;
if ~isempty(locs1_y)
    plot(time(locs1_y), pks1_y, '^b', 'DisplayName', 'Right Heel Strikes');
end
if ~isempty(locs_valleys1_y)
    plot(time(locs_valleys1_y), -valleys1_y, 'ob', 'DisplayName', 'Right Toe Offs');
end
plot(time, gyro_2_smoothed(:,2), 'r', 'DisplayName', 'Left Foot Angular Velocity');
if ~isempty(locs2_y)
    plot(time(locs2_y), pks2_y, '^r', 'DisplayName', 'Left Heel Strikes');
end
if ~isempty(locs_valleys2_y)
    plot(time(locs_valleys2_y), -valleys2_y, 'or', 'DisplayName', 'Left Toe Offs');
end
title(['Y-axis Acceleration - SI Peak: ' num2str(SI_peak_y,'%.2f') '%, SI Mean: ' num2str(SI_mean_y,'%.2f') '%']);
xlabel('Time (s)');
ylabel('Angular Velocity (rad/s)');
legend('show');

subplot(3,1,3);
plot(time, gyro_1_smoothed(:,3), 'b', 'DisplayName', 'Right Foot Angular Velocity');
hold on;
if ~isempty(locs1_z)
    plot(time(locs1_z), pks1_z, '^b', 'DisplayName', 'Right Heel Strikes');
end
if ~isempty(locs_valleys1_z)
    plot(time(locs_valleys1_z), -valleys1_z, 'ob', 'DisplayName', 'Right Toe Offs');
end
plot(time, gyro_2_smoothed(:,3), 'r', 'DisplayName', 'Left Foot Angular Velocity');
if ~isempty(locs2_z)
    plot(time(locs2_z), pks2_z, '^r', 'DisplayName', 'Left Heel Strikes');
end
if ~isempty(locs_valleys2_z)
    plot(time(locs_valleys2_z), -valleys2_z, 'or', 'DisplayName', 'Left Toe Offs');
end
title(['Z-axis Acceleration - SI Peak: ' num2str(SI_peak_z,'%.2f') '%, SI Mean: ' num2str(SI_mean_z,'%.2f') '%']);
xlabel('Time (s)');
ylabel('Angular Velocity (rad/s)');
legend('show');

peak_right_x = max(acc_1_smoothed(:,1));
peak_left_x = max(acc_2_smoothed(:,1));

peak_right_y = max(acc_1_smoothed(:,2));
peak_left_y = max(acc_2_smoothed(:,2));

peak_right_z = max(acc_1_smoothed(:,3));
peak_left_z = max(acc_2_smoothed(:,3));

% Menghitung mean values untuk setiap sumbu
mean_right_x = mean(acc_1_smoothed(:,1));
mean_left_x = mean(acc_2_smoothed(:,1));

mean_right_y = mean(acc_1_smoothed(:,2));
mean_left_y = mean(acc_2_smoothed(:,2));

mean_right_z = mean(acc_1_smoothed(:,3));
mean_left_z = mean(acc_2_smoothed(:,3));

% Menghitung SI menggunakan peak values
SI_peak_x = abs(peak_right_x - peak_left_x) / (0.5 * (peak_right_x + peak_left_x)) * 100;
SI_peak_y = abs(peak_right_y - peak_left_y) / (0.5 * (peak_right_y + peak_left_y)) * 100;
SI_peak_z = abs(peak_right_z - peak_left_z) / (0.5 * (peak_right_z + peak_left_z)) * 100;

% Menghitung SI menggunakan mean values
SI_mean_x = abs(mean_right_x - mean_left_x) / (0.5 * (mean_right_x + mean_left_x)) * 100;
SI_mean_y = abs(mean_right_y - mean_left_y) / (0.5 * (mean_right_y + mean_left_y)) * 100;
SI_mean_z = abs(mean_right_z - mean_left_z) / (0.5 * (mean_right_z + mean_left_z)) * 100;

fprintf('\nSymmetry Index using Peak Values:\n');
fprintf('X-axis: %.2f%%\n', SI_peak_x);
fprintf('Y-axis: %.2f%%\n', SI_peak_y);
fprintf('Z-axis: %.2f%%\n', SI_peak_z);

fprintf('\nSymmetry Index using Mean Values:\n');
fprintf('X-axis: %.2f%%\n', SI_mean_x);
fprintf('Y-axis: %.2f%%\n', SI_mean_y);
fprintf('Z-axis: %.2f%%\n', SI_mean_z);

figure('Position', [50, 50, 100, 100]);

subplot(3,1,1);
plot(acc_1_smoothed(:,1), 'b-', 'DisplayName', 'Right Foot');
hold on;
plot(acc_2_smoothed(:,1), 'r-', 'DisplayName', 'Left Foot');
title(['X-axis Acceleration - SI Peak: ' num2str(SI_peak_x,'%.2f') '%, SI Mean: ' num2str(SI_mean_x,'%.2f') '%']);
ylabel('Acceleration (m/s^2)');
legend;
grid on;

subplot(3,1,2);
plot(acc_1_smoothed(:,2), 'b-', 'DisplayName', 'Right Foot');
hold on;
plot(acc_2_smoothed(:,2), 'r-', 'DisplayName', 'Left Foot');
title(['Y-axis Acceleration - SI Peak: ' num2str(SI_peak_y,'%.2f') '%, SI Mean: ' num2str(SI_mean_y,'%.2f') '%']);
ylabel('Acceleration (m/s^2)');
legend;
grid on;

subplot(3,1,3);
plot(acc_1_smoothed(:,3), 'b-', 'DisplayName', 'Right Foot');
hold on;
plot(acc_2_smoothed(:,3), 'r-', 'DisplayName', 'Left Foot');
title(['Z-axis Acceleration - SI Peak: ' num2str(SI_peak_z,'%.2f') '%, SI Mean: ' num2str(SI_mean_z,'%.2f') '%']);
xlabel('Samples');
ylabel('Acceleration (m/s^2)');
legend;
grid on;
