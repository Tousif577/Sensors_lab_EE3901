clc; clear; close all;

%% Load data (Time | AccX | AccY | AccZ)
T = readtable(['walking_static.csv'],'VariableNamingRule','preserve');
t = T{:,1}; x = T{:,2}; y = T{:,3}; z = T{:,4};

%% Step 1: Raw Acceleration Magnitude
a = sqrt(x.^2+y.^2+z.^2);

%% Step 2: Filtering (Moving Average + remove baseline)
aFilt = movmean(a,10);
aFilt = aFilt - mean(aFilt);   % remove DC (gravity baseline)

%% Step 3: Step Detection (robust threshold)
fs = round(1/mean(diff(t)));   % sampling rate
thr = prctile(aFilt,85);       % robust threshold (85th percentile)
[pk,loc] = findpeaks(aFilt,'MinPeakHeight',thr,'MinPeakDistance',round(fs*0.3));
stepT = t(loc);
stepFreq = 1./diff(stepT);

%% Step 4: Activity Classification
win = 10;                   % window size in seconds
samplesWin = win*fs;
activityData = strings(length(t),1);

for i = 1:samplesWin:length(t)-samplesWin
    idx = i:i+samplesWin-1;
    [pks,~] = findpeaks(aFilt(idx),'MinPeakHeight',thr,'MinPeakDistance',round(fs*0.3));
    if numel(pks)<2
        act = "Idle";
    else
        % Estimate frequency from step intervals
        stepTimes = t(idx(1)) + (1:numel(pks));
        f = numel(pks)/win;   % steps/sec in window
        amp = mean(pks);
        
        if f<=0.5 && amp>5 && amp <10
            act="Walking";
        elseif f>0.5 && amp>=1 && amp <3
            act="Stairs Up";
        elseif f>1.2 && amp<1
            act="Stairs Down";
        else
            act="Unknown";
        end
    end
    activityData(idx) = act;
end

%% ================== ONE FIGURE WITH 3 SUBPLOTS ==================
figure;

% (311) Raw Data
subplot(3,1,1);
plot(t,a,'b');
title('Raw Acceleration Magnitude');
xlabel('Time (s)'); ylabel('Accel (m/s^2)');

% (312) Filtered Data + Steps
subplot(3,1,2);
plot(t,aFilt,'k'); hold on;
yline(thr,'--r','Threshold');   % show threshold line
plot(t(loc),pk,'ro');
title('Filtered Acceleration with Detected Steps');
xlabel('Time (s)'); ylabel('Accel (m/s^2)');
legend('Filtered','Threshold','Steps');

% (313) Activity Classification Timeline
subplot(3,1,3); hold on;
if any(activityData=="Walking")
    plot(t(activityData=="Walking"), 1*ones(sum(activityData=="Walking"),1), 'g.', 'DisplayName','Walking');
end
if any(activityData=="Stairs Up")
    plot(t(activityData=="Stairs Up"), 2*ones(sum(activityData=="Stairs Up"),1), 'r.', 'DisplayName','Stairs Up');
end
if any(activityData=="Stairs Down")
    plot(t(activityData=="Stairs Down"), 3*ones(sum(activityData=="Stairs Down"),1), 'b.', 'DisplayName','Stairs Down');
end
if any(activityData=="Idle")
    plot(t(activityData=="Idle"), 0*ones(sum(activityData=="Idle"),1), 'k.', 'DisplayName','Idle');
end
title('Activity Classification Over Time');
xlabel('Time (s)'); ylabel('Activity');
yticks([0 1 2 3]); yticklabels({'Idle','Walking','Stairs Up','Stairs Down'});
legend show;






