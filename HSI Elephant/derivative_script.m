%input files as txt with directory, can input as many files as you'd like
%to do
files_dir = ['472/results/REFLECTANCE_472.dat';
    '473/results/REFLECTANCE_473.dat';
    '474/results/REFLECTANCE_474.dat';
    '475/results/REFLECTANCE_475.dat';
    '476/results/REFLECTANCE_476.dat';
    '477/results/REFLECTANCE_477.dat'];

%%
warning('off','all') %polyfit gives a bunch of warnings so this is here to not crash the computer 

wlrange = [900 1003.58]; % removes bands above 900 nm
mid = 648.19; %centering wavelength for better fit

for f = 1:size(files_dir,1)
    hcube = hypercube(files_dir(f,:)); %load in files
    %hcube = removeBands(hcube, 'Wavelength', wlrange); %removes wavelengths in wlrange
    spectra = rescale(hcube.DataCube); %normalize data
    %initialize derivatives matrices
    dydx = zeros(512, 512, size(spectra,3));
    dy2dx2 = zeros(512, 512, size(spectra,3));
    smooth_spectra = zeros(512, 512, size(spectra,3));
    smooth_dydx = zeros(512, 512, size(spectra,3));
    smooth_dy2dx2 = zeros(512, 512, size(spectra,3));
    for i = 1:size(spectra,1)
        for j = 1:size(spectra,2)
            spectra_reshaped = reshape(spectra(i,j,:), [size(spectra,3),1]); %reshape spectra
            p = polyfit(hcube.Wavelength-mid, spectra_reshaped, 11); %fits 11 degree polynomial to spectra
            y_fit = polyval(p, hcube.Wavelength-mid); %takes polynomial and solves for y-values from inputed x-values
            
            q = polyder(p); %function of the first derivative
            y_fit_first_d = polyval(q,hcube.Wavelength-mid); %solves for y-values of first derivative
            w = polyder(q); %funciton of the second derivative
            y_fit_second_d = polyval(w,hcube.Wavelength-mid); %solves for y-values of second derivative

            firstd = gradient(spectra_reshaped)./gradient(hcube.Wavelength); %get first derivative
            secondd = gradient(firstd)./gradient(hcube.Wavelength); %get second derivative
            
            %save spectra to matrices
            smooth_spectra(i,j,:) = reshape(y_fit, [1 1 size(spectra_reshaped,1)]); % saves polynomial fit in case it's needed
            smooth_dydx(i,j,:) = reshape(y_fit_first_d, [1 1 size(spectra_reshaped,1)]);
            smooth_dy2dx2(i,j,:) = reshape(y_fit_second_d, [1 1 size(spectra_reshaped,1)]);
            dydx(i,j,:) = reshape(firstd,[1 1 size(spectra_reshaped,1)]); %save to shape
            dy2dx2(i,j,:) = reshape(secondd, [1 1 size(spectra_reshaped,1)]); %save to shape
        end
    end
    %Write to envi format
    smooth_spectra_hcube = assignData(hcube,':',':',':',smooth_spectra);
    smooth_dydx_hcube = assignData(hcube,':',':',':',smooth_dydx);
    smooth_dy2dx2_hcube = assignData(hcube,':',':',':',smooth_dy2dx2);
    dy2dx2_hcube = assignData(hcube,':',':',':',dy2dx2);
    dydx_hcube = assignData(hcube,':',':',':',dydx);
    
    %write to file
    enviwrite(smooth_spectra_hcube, append(files_dir(f,1:end-4),'_smooth_spectra1000'));
    enviwrite(smooth_dydx_hcube, append(files_dir(f,1:end- 4),'_smooth_firstd1000')); 
    enviwrite(smooth_dy2dx2_hcube, append(files_dir(f,1:end-4),'_smooth_secondd1000'));
    %enviwrite(dydx_hcube, append(files_dir(f,1:end-4),'_firstd'));
    %enviwrite(dy2dx2_hcube, append(files_dir(f,1:end-4),'_secondd'));    
end
%%
%Elephant1_Left = hypercube('472/results/REFLECTANCE_472.dat');
%Elephant1_Smooth = hypercube('472/results/REFLECTANCE_472_smooth_spectra.dat');
%wlrange = [900 1003.58];
%Elephant1_Left = removeBands(Elephant1_Left, 'Wavelength', wlrange);
%Red = [380 213; 359 200; 326 272; 292 122; 284 210; 288 275; 426 97; 331 317; 303 434; 326 404];

Elephant1_Left = hypercube('474/results/REFLECTANCE_474.dat');
Elephant1_Smooth = hypercube('474/results/REFLECTANCE_474_smooth_spectra.dat');

Red = [185 85; 311 243; 224 180; 406 383];
wlrange = [900 1003.58];
Elephant1_Left = removeBands(Elephant1_Left, 'Wavelength', wlrange);

Elephant_yellow=[];
Elephant_smooth = [];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Left.DataCube(Red(i,2),Red(i,1),:);
    Elephant_smooth(i,:) = Elephant1_Smooth.DataCube(Red(i,2),Red(i,1),:);
    Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
    Elephant_smooth_norm(i,:) = (Elephant_smooth(i,:)-min(Elephant_smooth(i,:)))/(max(Elephant_smooth(i,:))-min(Elephant_smooth(i,:)));
end
Elephant_mean = mean(Elephant_normalized,1);
Elehant_smooth_norm = mean(Elephant_smooth_norm,1);
% Given data
x = Elephant1_Left.Wavelength;  % Independent variable
y = Elephant_mean;              % Dependent variable

% Fit an 11th-degree polynomial
degree = 11;
[p, S, mu] = polyfit(x, y, degree);
%p = polyfit(x, y, degree);  % Polynomial coefficients

% Evaluate the polynomial at the given x-values

%y_fit = polyval(p, x);
y_fit = polyval(p, x, [], mu);

% Compute the first derivative
p_der1 = polyder(p);          % Coefficients of the first derivative
y_der1 = polyval(p_der1, x, [], mu);

% Compute the second derivative
p_der2 = polyder(p_der1);     % Coefficients of the second derivative
y_der2 = polyval(p_der2, x, [], mu);

% Find zero crossings for the first derivative
zero_crossings_der1 = x(find(diff(sign(y_der1)) ~= 0));

% Find zero crossings for the second derivative
zero_crossings_der2 = x(find(diff(sign(y_der2)) ~= 0));

close all
%plot(Elephant1_Left.Wavelength,Elephant_normalized)
figure 
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'mean spectra','15-degree polynomial smoothing'})
xlim([400 900]);
title('Yellow Pigment Diffuse Reflectance Spectra on Elephant 1, Left Side')


% Create the figure with subplots
figure;

% Plot the original spectra in the first subplot
subplot(3, 1, 1);
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
ylabel('Reflectance (normalized)')
legend({'mean spectra','11-degree polynomial smoothing'})
xlim([400 900]);
title('Yellow Pigment Diffuse Reflectance Spectra on Elephant 1, Top Side')
grid on;

% Plot the first derivative in the second subplot
subplot(3, 1, 2);
plot(x, y_der1, 'b-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1)
    xline(zero_crossings_der1(i), 'b--', sprintf('%.2f', zero_crossings_der1(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
ylabel('First Derivative');
xlim([400 900]);

grid on;

% Plot the second derivative in the third subplot
subplot(3, 1, 3);
plot(x, y_der2, 'r--', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2)
    xline(zero_crossings_der2(i), 'r-.', sprintf('%.2f', zero_crossings_der2(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
xlabel('Wavelength');
ylabel('Second Derivative');
xlim([400 900]);

grid on;

%%

Elephant1_Left = hypercube('472/results/REFLECTANCE_472.dat');
Elephant1_Smooth = hypercube('472/results/REFLECTANCE_472_smooth_spectra.dat');

Red = [295 255; 353 225; 305 134; 419 335; 409 75];
wlrange = [900 1003.58];
Elephant1_Left = removeBands(Elephant1_Left, 'Wavelength', wlrange);

Elephant_yellow=[];
Elephant_smooth = [];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Left.DataCube(Red(i,2),Red(i,1),:);
    Elephant_smooth(i,:) = Elephant1_Smooth.DataCube(Red(i,2),Red(i,1),:);
    Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
    Elephant_smooth_norm(i,:) = (Elephant_smooth(i,:)-min(Elephant_smooth(i,:)))/(max(Elephant_smooth(i,:))-min(Elephant_smooth(i,:)));
end
Elephant_mean = mean(Elephant_normalized,1);
Elehant_smooth_norm = mean(Elephant_smooth_norm,1);
% Given data
x = Elephant1_Left.Wavelength;  % Independent variable
y = Elephant_mean;              % Dependent variable

% Fit an 11th-degree polynomial
degree = 11;
[p, S, mu] = polyfit(x, y, degree);
%p = polyfit(x, y, degree);  % Polynomial coefficients

% Evaluate the polynomial at the given x-values

%y_fit = polyval(p, x);
y_fit = polyval(p, x, [], mu);

% Compute the first derivative
p_der1 = polyder(p);          % Coefficients of the first derivative
y_der1 = polyval(p_der1, x, [], mu);

% Compute the second derivative
p_der2 = polyder(p_der1);     % Coefficients of the second derivative
y_der2 = polyval(p_der2, x, [], mu);

% Find zero crossings for the first derivative
zero_crossings_der1 = x(find(diff(sign(y_der1)) ~= 0));

% Find zero crossings for the second derivative
zero_crossings_der2 = x(find(diff(sign(y_der2)) ~= 0));

close all
%plot(Elephant1_Left.Wavelength,Elephant_normalized)
figure 
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'mean spectra','15-degree polynomial smoothing'})
xlim([400 900]);
title('Blue Pigment Diffuse Reflectance Spectra on Elephant 1, Left Side')


% Create the figure with subplots
figure;

% Plot the original spectra in the first subplot
subplot(3, 1, 1);
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
ylabel('Reflectance (normalized)')
legend({'mean spectra','11-degree polynomial smoothing'})
xlim([400 900]);
title('Blue Pigment Diffuse Reflectance Spectra on Elephant 1, Left Side')
grid on;

% Plot the first derivative in the second subplot
subplot(3, 1, 2);
plot(x, y_der1, 'b-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1)
    xline(zero_crossings_der1(i), 'b--', sprintf('%.2f', zero_crossings_der1(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
ylabel('First Derivative');
xlim([400 900]);

grid on;

% Plot the second derivative in the third subplot
subplot(3, 1, 3);
plot(x, y_der2, 'r--', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2)
    xline(zero_crossings_der2(i), 'r-.', sprintf('%.2f', zero_crossings_der2(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
xlabel('Wavelength');
ylabel('Second Derivative');
xlim([400 900]);

grid on;

%%
Elephant1_Left = hypercube('472/results/REFLECTANCE_472.dat');
Elephant1_Smooth = hypercube('472/results/REFLECTANCE_472_smooth_spectra.dat');

Red = [444 111; 446 309; 329 163; 302 348];
Elephant_yellow=[];
Elephant_smooth = [];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Left.DataCube(Red(i,2),Red(i,1),:);
    Elephant_smooth(i,:) = Elephant1_Smooth.DataCube(Red(i,2),Red(i,1),:);
    Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
    Elephant_smooth_norm(i,:) = (Elephant_smooth(i,:)-min(Elephant_smooth(i,:)))/(max(Elephant_smooth(i,:))-min(Elephant_smooth(i,:)));
end
Elephant_mean = mean(Elephant_normalized,1);
Elehant_smooth_norm = mean(Elephant_smooth_norm,1);
% Given data
x = Elephant1_Left.Wavelength;  % Independent variable
y = Elephant_mean;              % Dependent variable

% Fit an 11th-degree polynomial
degree = 18;
[p, S, mu] = polyfit(x, y, degree);
%p = polyfit(x, y, degree);  % Polynomial coefficients

% Evaluate the polynomial at the given x-values

%y_fit = polyval(p, x);
y_fit = polyval(p, x, [], mu);

% Compute the first derivative
p_der1 = polyder(p);          % Coefficients of the first derivative
y_der1 = polyval(p_der1, x, [], mu);

% Compute the second derivative
p_der2 = polyder(p_der1);     % Coefficients of the second derivative
y_der2 = polyval(p_der2, x, [], mu);

% Find zero crossings for the first derivative
zero_crossings_der1 = x(find(diff(sign(y_der1)) ~= 0));

% Find zero crossings for the second derivative
zero_crossings_der2 = x(find(diff(sign(y_der2)) ~= 0));

close all
%plot(Elephant1_Left.Wavelength,Elephant_normalized)
figure 
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'mean spectra','15-degree polynomial smoothing'})
xlim([400 900]);
title('Black Pigment Diffuse Reflectance Spectra on Elephant 1, Left Side')


% Create the figure with subplots
figure;

% Plot the original spectra in the first subplot
subplot(3, 1, 1);
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
ylabel('Reflectance (normalized)')
legend({'mean spectra','11-degree polynomial smoothing'})
xlim([400 900]);
title('Black Pigment Diffuse Reflectance Spectra on Elephant 1, Left Side')
grid on;

% Plot the first derivative in the second subplot
subplot(3, 1, 2);
plot(x, y_der1, 'b-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1)
    xline(zero_crossings_der1(i), 'b--', sprintf('%.2f', zero_crossings_der1(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
ylabel('First Derivative');
xlim([400 900]);

grid on;

% Plot the second derivative in the third subplot
subplot(3, 1, 3);
plot(x, y_der2, 'r--', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2)
    xline(zero_crossings_der2(i), 'r-.', sprintf('%.2f', zero_crossings_der2(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
xlabel('Wavelength');
ylabel('Second Derivative');
xlim([400 900]);

grid on;
%%
Elephant1_Top = hypercube('474/results/REFLECTANCE_474_smooth_spectra1000.dat');

Red = [185 85; 311 243; 224 180; 406 383];
Elephant_yellow=[];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Top.DataCube(Red(i,2),Red(i,1),:);
    Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
end
plot(Elephant1_Top.Wavelength,Elephant_normalized)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'Point 1','Point 2','Point 3','Point 4','Point 5','Point 6','Point 7','Point 8','Point 9','Point 10'})
title('Yellow Pigment Diffuse Reflectance Spectra on Elephant 1, Top Side')
%%
Elephant1_Top = hypercube('474/results/REFLECTANCE_474_smooth_firstd.dat');

Red = [185 85; 311 243; 224 180; 406 383];
Elephant_yellow=[];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Top.DataCube(Red(i,2),Red(i,1),:);
end
plot(Elephant1_Top.Wavelength,Elephant_yellow)
hold on
yline(0,'k--')
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'Point 1','Point 2','Point 3','Point 4'})
title('Yellow Pigment Diffuse Reflectance Spectra, First Derivative on Elephant 1, Top Side')

%%
Elephant1_Top = hypercube('473/results/REFLECTANCE_473_smooth_spectra.dat');

Red = [329 164; 447 306; 444 107; 320 42; 338 257];
Elephant_yellow=[];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Top.DataCube(Red(i,2),Red(i,1),:);
    Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
end
plot(Elephant1_Top.Wavelength,Elephant_normalized)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'Point 1','Point 2','Point 3','Point 4','Point 5','Point 6','Point 7','Point 8','Point 9','Point 10'})
title('Black Pigment Diffuse Reflectance Spectra on Elephant 1, Right Side')
%%
Elephant1_Top = hypercube('473/results/REFLECTANCE_473_smooth_firstd.dat');

Red = [401 131; 270 56; 282 175; 280 266; 247 383];Elephant_yellow=[];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Top.DataCube(Red(i,2),Red(i,1),:);
end
plot(Elephant1_Top.Wavelength,Elephant_yellow)
hold on
yline(0,'k--')
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'Point 1','Point 2','Point 3','Point 4','Point 5'})
title('Black Pigment Diffuse Reflectance Spectra, First Derivative on Elephant 1, Right Side')

%%


%%
Elephant1_Top = hypercube('472/results/REFLECTANCE_472_smooth_spectra.dat');

Red = [280 42; 318 429; 306 71; 325 137; 195 353];
Elephant_yellow=[];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Top.DataCube(Red(i,2),Red(i,1),:);
   Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
end
plot(Elephant1_Top.Wavelength,Elephant_yellow)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'Point 1','Point 2','Point 3','Point 4','Point 5','Point 6','Point 7','Point 8','Point 9','Point 10'})
title('White Pigment Diffuse Reflectance Spectra on Elephant 1, Top Side')
%%
Elephant1_Top = hypercube('472/results/REFLECTANCE_472_smooth_firstd.dat');

Red = [136 320; 167 248; 345 330; 327 180; 66 311; 442 261; 42 275];
Elephant_yellow=[];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Top.DataCube(Red(i,2),Red(i,1),:);
end
plot(Elephant1_Top.Wavelength,Elephant_yellow)
hold on
yline(0,'k--')
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'Point 1','Point 2','Point 3','Point 4','Point 5'})
title('White Pigment Diffuse Reflectance Spectra, First Derivative on Elephant 1, Right Side')

%%
Elephant1_Left = hypercube('472/results/REFLECTANCE_472_smooth_spectra.dat').DataCube;
Elephant1_Right = hypercube('473/results/REFLECTANCE_473_smooth_spectra.dat').DataCube;
Elephant1_Top = hypercube('474/results/REFLECTANCE_474_smooth_spectra.dat').DataCube;
Elephant2_Left = hypercube('475/results/REFLECTANCE_475_smooth_spectra.dat').DataCube;
Elephant2_Right = hypercube('476/results/REFLECTANCE_476_smooth_spectra.dat').DataCube;
Elephant2_Top = hypercube('477/results/REFLECTANCE_477_smooth_spectra.dat').DataCube;

Elephant1_Left_firstd = hypercube('472/results/REFLECTANCE_472_smooth_firstd.dat').DataCube;
Elephant1_Right_firstd = hypercube('473/results/REFLECTANCE_473_smooth_firstd.dat').DataCube;
Elephant1_Top_firstd = hypercube('474/results/REFLECTANCE_474_smooth_firstd.dat').DataCube;
Elephant2_Left_firstd = hypercube('475/results/REFLECTANCE_475_smooth_firstd.dat').DataCube;
Elephant2_Right_firstd = hypercube('476/results/REFLECTANCE_476_smooth_firstd.dat').DataCube;
Elephant2_Top_firstd = hypercube('477/results/REFLECTANCE_477_smooth_firstd.dat').DataCube;


%%
wavelength = hypercube('472/results/REFLECTANCE_472_smooth_firstd.dat').Wavelength;
Elephant1_Red = reshape(Elephant1_Left(211,284,:),170,1);
Elephant2_Red = reshape(Elephant2_Right(300,233,:),170,1);
plot(wavelength,Elephant1_Red,'r')
hold on
plot(wavelength,Elephant2_Red,'r--');
hold on
Elephant1_Yellow = reshape(Elephant1_Top(177,209,:),170,1);
Elephant2_Yellow = reshape(Elephant2_Top(244,352,:),170,1);
plot(wavelength,Elephant1_Yellow,'Color', '#EDB120')
hold on
plot(wavelength,Elephant2_Yellow,'--','Color', '#EDB120');

Elephant1_Blue = reshape(Elephant1_Top(169,227,:),170,1);
Elephant2_Blue = reshape(Elephant2_Top(243,366,:),170,1);

plot(wavelength,Elephant1_Blue,'Color', '#0072BD');
hold on
plot(wavelength,Elephant2_Blue,'--','Color', '#0072BD');
title('Reflectance Spectra Comparison between both Elephants (not normalized)')
xlabel('wavelength (nm)')
ylabel('Reflectance')
xlim([380 900])
legend({'Elephant 1 Red', 'Elephant 2 Red', 'Elephant 1 Yellow', 'Elephant 2 Yellow', 'Elephant 1 Blue', 'Elephant 2 Blue'})

%%
Elephant1_Red = reshape(Elephant1_Left_firstd(211,284,:),170,1);
Elephant2_Red = reshape(Elephant2_Right_firstd(300,233,:),170,1);
Elephant1_Yellow = reshape(Elephant1_Top_firstd(177,209,:),170,1);
Elephant2_Yellow = reshape(Elephant2_Top_firstd(244,352,:),170,1);
Elephant1_Blue = reshape(Elephant1_Top_firstd(169,227,:),170,1);
Elephant2_Blue = reshape(Elephant2_Top_firstd(243,366,:),170,1);

plot(wavelength,Elephant1_Red,'r')
hold on
plot(wavelength,Elephant2_Red,'r--');
yline(0,'k--')
plot(wavelength,Elephant1_Yellow,'Color', '#EDB120')
hold on
plot(wavelength,Elephant2_Yellow,'--','Color', '#EDB120');
plot(wavelength,Elephant1_Blue,'Color', '#0072BD');
hold on
plot(wavelength,Elephant2_Blue,'--','Color', '#0072BD');
title('First Derivative Reflectance Spectra Comparison between both Elephants')
xlabel('wavelength (nm)')
ylabel('Reflectance')
xlim([380 900])
legend({'Elephant 1 Red', 'Elephant 2 Red', 'Elephant 1 Yellow', 'Elephant 2 Yellow', 'Elephant 1 Blue', 'Elephant 2 Blue'})

%%
spectra = load('database/vermilion nat.txt');
red_ochre = load('database/red ochre.txt');
lac = load('database/lac die.txt');
madder = load('database/madder lake.txt');
safflower = load('database/NY 5 - safflower.txt');
pyrrole = load('database/PR 264 - pyrrole red.txt');
realgar = load('database/realgar.txt');
red_lead = load('database/red lead.txt');


% Plot the original data
plot(spectra(:, 1), spectra(:, 2), 'LineWidth', 1.5);
hold on
plot(red_ochre(:, 1), red_ochre(:, 2), 'LineWidth', 1.5);
hold on
plot(lac(:, 1), lac(:, 2), 'LineWidth', 1.5);
hold on
plot(madder(:, 1), madder(:, 2), 'LineWidth', 1.5);
hold on
plot(safflower(:, 1), safflower(:, 2), 'LineWidth', 1.5);
hold on
plot(pyrrole(:, 1), pyrrole(:, 2), 'LineWidth', 1.5);
hold on
plot(realgar(:, 1), realgar(:, 2), 'LineWidth', 1.5);
hold on
plot(red_lead(:,1), red_lead(:,2), 'LineWidth', 1.5);

legend({'vermillion','red ochre','lac dye','madder lake','safflower','pyrrole','realgar'});
xlabel('Wavelength (nm)');
ylabel('Intensity');
title('Red Spectral Data');
set(gca, 'FontSize', 12);
grid on

% Customize the axes
set(gca, 'FontSize', 12);

%%
% Load the data from the file
yellow_ochre = load('database/yellow ochre.txt');
gamboge = load('database/gamboge.txt');
hansa_yellow = load('database/PY 3 hansa yellow 10G - pigments checker acrylic - GorgiasUV.txt');
orpiment = load('database/orpiment.txt');
naples = load('database/naples yellow.txt');
raw_sienna = load('database/raw sienna.txt');
raw_umber = load('database/raw umber.txt');
saffron = load('database/saffron.txt');



% Create the plot
figure;
plot(yellow_ochre(:,1), yellow_ochre(:,2), 'LineWidth', 1.5);
hold on
plot(gamboge(:,1), gamboge(:,2), 'LineWidth', 1.5);
hold on
plot(hansa_yellow(:,1), hansa_yellow(:,2), 'LineWidth', 1.5);
hold on
plot(orpiment(:,1), orpiment(:,2), 'LineWidth', 1.5);
hold on
plot(naples(:,1), naples(:,2), 'LineWidth', 1.5);
hold on
plot(raw_sienna(:,1), raw_sienna(:,2), 'LineWidth', 1.5);
hold on
plot(saffron(:,1), saffron(:,2),'LineWidth', 1.5);



grid on

% Add labels and title
xlabel('Wavelength (nm)');
ylabel('Intensity');
title('Yellow Spectral Data');
legend({'yellow ochre','gamboge','hansa yellow','orpiment','naples yellow','raw sienna','saffron'})

% Customize the axes
set(gca, 'FontSize', 12);
%%

yellow_ochre = load('database/yellow ochre.txt');
raw_sienna = load('database/raw sienna.txt');

% Given data
x_yellow = yellow_ochre(:,1);  % Independent variable
y_yellow = yellow_ochre(:,2);              % Dependent variable

x_raw = raw_sienna(:,1);  % Independent variable
y_raw = raw_sienna(:,2);              % Dependent variable

% Fit an 11th-degree polynomial
degree = 25;
[p_yellow, S_yellow, mu_yellow] = polyfit(x_yellow, y_yellow, degree);
[p_raw, S_raw, mu_raw] = polyfit(x_raw, y_raw, degree);

y_fit_yellow = polyval(p_yellow, x_yellow, [], mu_yellow);
y_fit_raw = polyval(p_raw, x_raw, [], mu_raw);


% Compute the first derivative
p_der1_yellow = polyder(p_yellow);          % Coefficients of the first derivative
y_der1_yellow = polyval(p_der1_yellow, x_yellow, [], mu_yellow);
p_der1_raw = polyder(p_raw);          % Coefficients of the first derivative
y_der1_raw = polyval(p_der1_raw, x_raw, [], mu_raw);

% Compute the second derivative
p_der2_yellow = polyder(p_der1_yellow);     % Coefficients of the second derivative
y_der2_yellow = polyval(p_der2_yellow, x_yellow, [], mu_yellow);
p_der2_raw = polyder(p_der1_raw);     % Coefficients of the second derivative
y_der2_raw = polyval(p_der2_raw, x_raw, [], mu_raw);

% Find zero crossings for the first derivative
zero_crossings_der1_yellow = x_yellow(find(diff(sign(y_der1_yellow)) ~= 0));
zero_crossings_der1_raw = x_raw(find(diff(sign(y_der1_raw)) ~= 0));


% Find zero crossings for the second derivative
zero_crossings_der2_yellow = x_yellow(find(diff(sign(y_der2_yellow)) ~= 0));
zero_crossings_der2_raw = x_raw(find(diff(sign(y_der2_raw)) ~= 0));

close all
%plot(Elephant1_Left.Wavelength,Elephant_normalized)
figure 
plot(raw_sienna(:,1), raw_sienna(:,2),'ro', 'Linewidth',1)
hold on
plot(x_raw, y_fit_raw,'r-')
hold on
plot(yellow_ochre(:,1), yellow_ochre(:,2),'ko','Linewidth',1)
hold on
plot(x_yellow, y_fit_yellow,'k-')
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'raw sienna','','yellow ochre',''})
xlim([400 900]);
title('Raw sienna vs. yellow ochre')


% Create the figure with subplots
figure;

% Plot the original spectra in the first subplot
subplot(3, 1, 1);
%plot(raw_sienna(:,1), raw_sienna(:,2),'ro')
hold on
plot(x_raw, y_fit_raw,'r-','LineWidth', 2)
hold on
%plot(yellow_ochre(:,1), yellow_ochre(:,2),'ko')
hold on
plot(x_yellow, y_fit_yellow,'k-','LineWidth', 2)
ylabel('Reflectance (normalized)')
legend({'raw sienna','yellow ochre'})

xlim([400 900]);
title('Raw Sienna vs. Yellow Ochre')

grid on;

% Plot the first derivative in the second subplot
subplot(3, 1, 2);
plot(x_raw, y_der1_raw, 'r-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1_raw)
    xline(zero_crossings_der1_raw(i), 'r--', sprintf('%.2f', zero_crossings_der1_raw(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
plot(x_yellow, y_der1_yellow, 'k-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1_yellow)
    xline(zero_crossings_der1_yellow(i), 'k--', sprintf('%.2f', zero_crossings_der1_yellow(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
ylabel('First Derivative');

xlim([400 900]);

grid on;

% Plot the second derivative in the third subplot
subplot(3, 1, 3);
plot(x_raw, y_der2_raw, 'r-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2_raw)
    xline(zero_crossings_der2_raw(i), 'r-.', sprintf('%.2f', zero_crossings_der2_raw(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
hold on
plot(x_yellow, y_der2_yellow, 'k-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2_yellow)
    xline(zero_crossings_der2_yellow(i), 'k-.', sprintf('%.2f', zero_crossings_der2_yellow(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
xlabel('Wavelength');
ylabel('Second Derivative');
xlim([400 900]);

grid on;


%%

indigo = load('database/indigo.txt');
ultramarine = load('database/ultramarine b nat.txt');
prussian = load('database/prussian blue.txt');
% Create the plot
figure;
plot(indigo(:,1), indigo(:,2), 'LineWidth', 1.5);
hold on
plot(ultramarine(:,1), ultramarine(:,2), 'LineWidth', 1.5);
hold on
plot(prussian(:,1), prussian(:,2), 'LineWidth', 1.5);


grid on

% Add labels and title
xlabel('Wavelength (nm)');
ylabel('Intensity');
title('Blue Spectral Data');
legend({'Indigo','Ultramarine Blue','Prussian Blue'})

% Customize the axes
set(gca, 'FontSize', 12);

%%
bone_black = load('database/bone black.txt');
ivory_black = load('database/ivory black.txt');
lamp_black = load('database/lamp black - pigments checker acrylic - GorgiasUV.txt');
aniline = load('database/PBk 1 - aniline black.txt');
vine = load('database/vine black.txt');

figure;
% plot(bone_black(:,1), bone_black(:,2), 'LineWidth', 1.5);
% hold on
% plot(ivory_black(:,1), ivory_black(:,2), 'LineWidth', 1.5);
% hold on
% plot(lamp_black(:,1), lamp_black(:,2), 'LineWidth', 1.5);
% hold on
% plot(aniline(:,1), aniline(:,2), 'LineWidth', 1.5);
% hold on
% plot(vine(:,1), vine(:,2), 'LineWidth', 1.5);
plot(bone_black(:,1), normalize(bone_black(:,2)), 'LineWidth', 1.5);
hold on
plot(ivory_black(:,1), normalize(ivory_black(:,2)), 'LineWidth', 1.5);
hold on
plot(lamp_black(:,1), normalize(lamp_black(:,2)), 'LineWidth', 1.5);
hold on
plot(aniline(:,1), normalize(aniline(:,2)), 'LineWidth', 1.5);
hold on
plot(vine(:,1), normalize(vine(:,2)), 'LineWidth', 1.5);

grid on

% Add labels and title
xlabel('Wavelength (nm)');
ylabel('normalized Intensity');
title('Black Spectral Data');
legend({'bone','ivory','lamp','aniline','vine'})

% Customize the axes
set(gca, 'FontSize', 12);

%%

%%
Elephant1_Left = hypercube('474/results/REFLECTANCE_474.dat');
Elephant1_Smooth = hypercube('474/results/REFLECTANCE_474_smooth_spectra.dat');

Red = [185 85; 311 243; 224 180; 406 383];
wlrange = [900 1003.58];
Elephant1_Left = removeBands(Elephant1_Left, 'Wavelength', wlrange);

Elephant_yellow=[];
Elephant_smooth = [];
Elephant_normalized=[];
for i=1:size(Red,1)
    Elephant_yellow(i,:) = Elephant1_Left.DataCube(Red(i,2),Red(i,1),:);
    Elephant_smooth(i,:) = Elephant1_Smooth.DataCube(Red(i,2),Red(i,1),:);
    Elephant_normalized(i,:)= (Elephant_yellow(i,:)-min(Elephant_yellow(i,:)))/(max(Elephant_yellow(i,:))-min(Elephant_yellow(i,:)));
    Elephant_smooth_norm(i,:) = (Elephant_smooth(i,:)-min(Elephant_smooth(i,:)))/(max(Elephant_smooth(i,:))-min(Elephant_smooth(i,:)));
end
Elephant_mean = mean(Elephant_normalized,1);
Elehant_smooth_norm = mean(Elephant_smooth_norm,1);
% Given data
x = Elephant1_Left.Wavelength;  % Independent variable
y = Elephant_mean;              % Dependent variable

% Fit an 11th-degree polynomial
degree = 11;
[p, S, mu] = polyfit(x, y, degree);
%p = polyfit(x, y, degree);  % Polynomial coefficients

% Evaluate the polynomial at the given x-values

%y_fit = polyval(p, x);
y_fit = polyval(p, x, [], mu);

% Compute the first derivative
p_der1 = polyder(p);          % Coefficients of the first derivative
y_der1 = polyval(p_der1, x, [], mu);

% Compute the second derivative
p_der2 = polyder(p_der1);     % Coefficients of the second derivative
y_der2 = polyval(p_der2, x, [], mu);

% Find zero crossings for the first derivative
zero_crossings_der1 = x(find(diff(sign(y_der1)) ~= 0));

% Find zero crossings for the second derivative
zero_crossings_der2 = x(find(diff(sign(y_der2)) ~= 0));

close all
%plot(Elephant1_Left.Wavelength,Elephant_normalized)
figure 
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
xlabel('Wavelength (nm)')
ylabel('Reflectance (normalized)')
legend({'mean spectra','15-degree polynomial smoothing'})
xlim([400 900]);
title('Yellow Pigment Diffuse Reflectance Spectra on Elephant 1, Left Side')


% Create the figure with subplots
figure;

% Plot the original spectra in the first subplot
subplot(3, 1, 1);
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
ylabel('Reflectance (normalized)')
legend({'mean spectra','11-degree polynomial smoothing'})
xlim([400 900]);
title('Yellow Pigment Diffuse Reflectance Spectra on Elephant 1, Top Side')
grid on;

% Plot the first derivative in the second subplot
subplot(3, 1, 2);
plot(x, y_der1, 'b-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1)
    xline(zero_crossings_der1(i), 'b--', sprintf('%.2f', zero_crossings_der1(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
ylabel('First Derivative');
xlim([400 900]);

grid on;

% Plot the second derivative in the third subplot
subplot(3, 1, 3);
plot(x, y_der2, 'r--', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2)
    xline(zero_crossings_der2(i), 'r-.', sprintf('%.2f', zero_crossings_der2(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
xlabel('Wavelength');
ylabel('Second Derivative');
xlim([400 900]);

grid on;

%%
Elephant1_Left = hypercube('475/results/REFLECTANCE_475.dat');

tusk = [321 447; 321 459; 316 471];

tail = [306 67; 291 67; 275 68];

white = [363 258; 379 184; 362 156];

bare = [197 184; 220 220; 213 392];
wlrange = [900 1003.58];
Elephant1_Left = removeBands(Elephant1_Left, 'Wavelength', wlrange);

Elephant_tusk = [];
Elephant_tail = [];
Elephant_white = [];
Elephant_bare = [];

for i=1:size(tusk,1)
    Elephant_tusk(i,:) = Elephant1_Left.DataCube(tusk(i,2),tusk(i,1),:);
end
tusk_mean = mean(Elephant_tusk);
for i=1:size(tail,1)
    Elephant_tail(i,:) = Elephant1_Left.DataCube(tail(i,2),tail(i,1),:);
end
tail_mean = mean(Elephant_tail);

for i=1:size(white,1)
    Elephant_white(i,:) = Elephant1_Left.DataCube(white(i,2),white(i,1),:);
end

white_mean = mean(Elephant_white);

for i=1:size(bare,1)
    Elephant_bare(i,:) = Elephant1_Left.DataCube(bare(i,2),bare(i,1),:);
end

bare_mean = mean(Elephant_bare);

degree = 11;
[p_tusk, S_tusk, mu_tusk] = polyfit(Elephant1_Left.Wavelength, tusk_mean, degree);
[p_tail, S_tail, mu_tail] = polyfit(Elephant1_Left.Wavelength, tail_mean, degree);
[p_white, S_white, mu_white] = polyfit(Elephant1_Left.Wavelength, white_mean, degree);
[p_bare, S_bare, mu_bare] = polyfit(Elephant1_Left.Wavelength, bare_mean, degree);

x = Elephant1_Left.Wavelength;
y_fit_tusk = polyval(p_tusk, x, [], mu_tusk);
y_fit_tail = polyval(p_tail, x, [], mu_tail);
y_fit_white = polyval(p_white, x, [], mu_white);
y_fit_bare = polyval(p_bare, x, [], mu_bare);


plot(x,tusk_mean,'*')
hold on
plot(x,tail_mean,'*')
hold on
plot(x,white_mean, '*')
hold on
plot(x,bare_mean,'*')
hold on
plot(x,y_fit_tusk,'k--')
plot(x,y_fit_tail,'k--')

plot(x,y_fit_white,'k--')

plot(x,y_fit_bare,'k--')


legend({'tusk','tail','white tapestry','less-white tapestry'})
xlabel('Wavelength');
ylabel('Mean Reflectance');
xlim([400 900]);


%%
p=p_bare;
Elephant_mean = bare_mean;
y_fit = y_fit_bare;

% Compute the first derivative
p_der1 = polyder(p);          % Coefficients of the first derivative
y_der1 = polyval(p_der1, x, [], mu);

% Compute the second derivative
p_der2 = polyder(p_der1);     % Coefficients of the second derivative
y_der2 = polyval(p_der2, x, [], mu);

% Find zero crossings for the first derivative
zero_crossings_der1 = x(find(diff(sign(y_der1)) ~= 0));

% Find zero crossings for the second derivative
zero_crossings_der2 = x(find(diff(sign(y_der2)) ~= 0));

close all

% Create the figure with subplots
figure;

% Plot the original spectra in the first subplot
subplot(3, 1, 1);
plot(Elephant1_Left.Wavelength, Elephant_mean,'LineWidth', 2)
hold on
plot(x, y_fit,'LineWidth', 2)
ylabel('Reflectance (normalized)')
legend({'mean spectra','11-degree polynomial smoothing'})
xlim([400 900]);
title('White Pigment Diffuse Reflectance Spectra on Less-White "Tapestry"')
grid on;

% Plot the first derivative in the second subplot
subplot(3, 1, 2);
plot(x, y_der1, 'b-', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der1)
    xline(zero_crossings_der1(i), 'b--', sprintf('%.2f', zero_crossings_der1(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
ylabel('First Derivative');
xlim([400 900]);

grid on;

% Plot the second derivative in the third subplot
subplot(3, 1, 3);
plot(x, y_der2, 'r--', 'LineWidth', 2);
hold on;
for i = 1:length(zero_crossings_der2)
    xline(zero_crossings_der2(i), 'r-.', sprintf('%.2f', zero_crossings_der2(i)), ...
          'LabelHorizontalAlignment', 'center', 'LabelVerticalAlignment', 'middle');
end
xlabel('Wavelength');
ylabel('Second Derivative');
xlim([400 900]);

grid on;

