% Title: CWT, XWT and WTC analyses of subduction zone toolbox data
% Author: Jodie Pall

% This script uses the cross wavelet and wavelet coherence toolbox developed by Aslak Grinsted, John Moore and Svetlana Jevrejeva.
% Citation: Grinsted, A., J. C. Moore, S. Jevrejeva (2004), Application of the cross wavelet transform and wavelet coherence to geophysical time series, 
% 			Nonlin. Process. Geophys., 11, 561566.  http://grinsted.github.io/wavelet-coherence/

% Last Edit: 2/03/2017

% Load Data
load co2proxy_pr2011.dat
load co2proxy_resampled.txt
load global_sz_length_carbonate_data.dat
load global_sz_length_data.dat
seriesname={'CIC subduction zone lengths' 'Proxy-CO_2 record (Park and Royer 2011)' 'Non-CIC subduction zone lengths' 'Global subduction zone lengths'};

acc = global_sz_length_carbonate_data(:,2);
sz = global_sz_length_data(:,2);
non_acc_raw = sz-acc;
age = 0:410;
co2raw = co2proxy_pr2011(:,2);
co2raw_age = co2proxy_pr2011(:,1);
co2rs = co2proxy_resampled(:,2);
co2rs_age = co2proxy_resampled(:,1);

% Resample CO2 proxy data
co2rs_resampled = resample(co2rs,co2rs_age,1);
co2_final = co2rs_resampled(1:411);

% Resampled and interpolated CO2 data
figure
hold on
grid on
set(gca,'xtick',0:50:410);
set(gca,'ytick',0:250:2850);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
plot(co2raw_age,co2raw,'+','Markersize',8.0,'Color',[0.75 0 0.75],'LineWidth',2.0)
plot(co2rs_age,co2rs,'-','Color',[0 0.75 0.75],'LineWidth',2.0)
plot(age,co2_final,'o-','MarkerSize',4.0,'Color','k','LineWidth',1.5)
xlim([0 410]);
xlabel('Age (Ma)')
ylabel('Atmospheric CO_2 concentration (ppm)')
legend('Raw data','Averaged value per time period','Resampled','Location','northeast')


figure
subplot(2,1,1);
hold on
set(gca,'fontsize',16);
plot(co2raw_age,co2raw,'-','Color',[0.93 0.69 0.13],'LineWidth',1.5)
plot(co2rs_age,co2rs,'o-','MarkerSize',4,'Color',[0 0.75 0.75],'LineWidth',1.5)
xlim([0 410]);
xlabel('Age (Ma)')
ylabel('Atmospheric CO_2 (ppm)')
legend('Raw data','Averaged value per time period','Location','northwest')
subplot(2,1,2);
hold on
set(gca,'fontsize',16);
plot(co2rs_age,co2rs,'Color',[0 0.75 0.75],'LineWidth',1.5)
plot(age,co2_final,'o-','MarkerSize',4,'Color','k','LineWidth',1.5)
xlim([0 410]);
ylim([0 3000]);
xlabel('Age (Ma)')
ylabel('Atmospheric CO_2 (ppm)')
legend('Averaged value per time period','Resampled','Location','northwest')


% plot intersecting arc lengths against non-intersecting arc lengths
figure;
hold on 
grid on
set(gca,'fontsize',16,'FontWeight','Normal');
set(gca,'XDir','Reverse');
plot(age,acc,'Color',[0 0.75 0.75],'LineWidth',2);
plot(age,non_acc_raw,'Color','k','LineWidth',2);
plot(age,sz,'Color','m','LineWidth',2);
xlim([0 410]);
xlabel('Age (Ma)');
ylabel('Arc Length (km)');
legend(seriesname{1},seriesname{3}, seriesname{4},'Location','northeast');

% Detrend data
acc_detrend = detrend(acc);
co2_detrend = detrend(co2_final);
sz_detrend = detrend(sz);
non_acc_detrend=sz_detrend-acc_detrend;

% Simple causal moving average filter in Matlab using filter()
windowSize = 7;
b = (1/windowSize)*ones(1,windowSize);
a = 1;

acc_filt = filter(b,a,acc_detrend);
acc_filt = acc_filt(windowSize:end);
co2_filt = filter(b,a,co2_detrend);
co2_filt = co2_filt(windowSize:end);
age_filt = age(floor(windowSize/2)+1:end-floor(windowSize/2));

sz_filt = filter(b,a,sz_detrend);
sz_filt = sz_filt(windowSize:end);

% Calculate non-carbonate intersecting arc lengths. 
non_acc = sz_filt - acc_filt;

% Plot filtered data
figure
subplot(4,1,1);
hold on 
set(gca,'fontsize',16,'FontWeight','Normal');
set(gca,'XDir','Reverse');
plot(age,acc_detrend,'Color',[0 0.75 0.75],'LineWidth',2);
plot(age_filt,acc_filt,'Color','k','LineWidth',2);
xlim([0 410]);
legend('Detrended','Filtered','Location','southwest');
title(seriesname{1},'FontWeight','Normal');
%
subplot(4,1,2);
hold on
set(gca,'fontsize',16);
plot(age,non_acc_detrend,'Color',[0.75 0 0.75],'LineWidth',2);
plot(age_filt,non_acc,'Color','k','LineWidth',2);
xlim([0 410]);
set(gca,'XDir','Reverse');
legend('Detrended','Filtered','Location','northeast');
title(seriesname{3},'FontWeight','Normal');
%
subplot(4,1,3);
hold on
set(gca,'fontsize',16,'FontWeight','Normal');
set(gca,'XDir','Reverse');
plot(age,sz_detrend,'Color',[0.85 0.33 0.1],'LineWidth',2);
plot(age_filt,sz_filt,'Color','k','LineWidth',2);
xlim([0 410]);
legend('Detrended','Filtered','Location','northeast');
title(seriesname{4},'FontWeight','Normal');
%
subplot(4,1,4);
hold on
set(gca,'fontsize',16,'FontWeight','Normal');
set(gca,'XDir','Reverse');
plot(age,co2_detrend,'Color',[0.3 0.75 0.93],'LineWidth',2);
plot(age_filt,co2_filt,'Color','k','LineWidth',2);
xlim([0 410]);
xlabel('Age (Ma)');
legend('Detrended','Filtered','Location','northeast');
title(seriesname{2},'FontWeight','Normal');


%CWT: CIA, NCIA and CO2
figure('color',[1 1 1])
hold on
subplot(4,1,1);
% tlim=[0,410];
wt(acc_filt);
ylabel('Period (Myr)');
title(seriesname{1},'FontWeight','Normal');
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
subplot(4,1,2)
wt(non_acc);
title(seriesname{3},'FontWeight','Normal')
set(gca,'XDir','Reverse');
colormap('jet')
set(gca,'fontsize',16);
ylabel('Period (Myr)');
subplot(4,1,3);
wt(sz_filt);
title(seriesname{4},'FontWeight','Normal')
set(gca,'XDir','Reverse');
colormap('jet')
set(gca,'fontsize',16);
ylabel('Period (Myr)');
subplot(4,1,4);
wt(co2_filt);
title(seriesname{2},'FontWeight','Normal')
set(gca,'XDir','Reverse');
colormap('jet')
set(gca,'fontsize',16);
xlabel('Age (Ma)');
ylabel('Period (Myr)');

figure()
subplot(2,3,1);
%XWT: Acc Model and CO2
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
xwt(acc_filt,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['XWT: ' seriesname{1}],'FontWeight','Normal')
subplot(2,3,4);
%WTC: Acc Model and CO2
wtc(acc_filt,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['WTC: ' seriesname{1}],'FontWeight','Normal')
subplot(2,3,2);
%XWT: Non-acc and CO2
xwt(non_acc,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['XWT: ' seriesname{3}],'FontWeight','Normal')
subplot(2,3,5);
%WTC: Non-acc and CO2
wtc(non_acc,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['WTC: ' seriesname{3}],'FontWeight','Normal')
subplot(2,3,3);
%XWT: Global SZ and CO2
xwt(sz_filt,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['XWT: ' seriesname{4}],'FontWeight','Normal')
subplot(2,3,6);
%WTC: Global SZ and CO2
wtc(sz_filt,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['WTC: ' seriesname{4}],'FontWeight','Normal')
subplot(2,3,1);
%XWT: Acc Model and CO2
xwt(acc_filt,co2_filt);
set(gca,'fontsize',16);
set(gca,'XDir','Reverse');
colormap('jet');
xlabel('Age (Ma)');
ylabel('Period (Myr)');
title(['XWT: ' seriesname{1}],'FontWeight','Normal')
