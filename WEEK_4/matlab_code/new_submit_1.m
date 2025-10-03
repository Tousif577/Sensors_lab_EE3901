clc; clear; close all;

%% Load data (time | ax | ay | az | aT)
T = readtable('static.csv','VariableNamingRule','preserve');
t = T{:,1}; 
a = T{:,5};   % already total acceleration (aT)

%% Step 1: Filtering (Moving Average + remove baseline)
aFilt = movmean(a,10);
aFilt = aFilt - mean(aFilt);   % remove DC

%% Step 2: Step Detection (adaptive threshold)
fs = round(1/mean(diff(t)));   % sampling rate
thr = mean(aFilt) + 0.5*std(aFilt);   % adaptive threshold
[pk,loc] = findpeaks(aFilt,'MinPeakHeight',thr,'MinPeakDistance',round(fs*0.4));
stepT = t(loc);

%% Step 3: Activity Classification (sliding windows)
win = 5;                        % seconds
samplesWin = win*fs;
activityData = strings(length(t),1);

for i = 1:samplesWin:length(t)-samplesWin
    idx = i:i+samplesWin-1;
    stdWin = std(aFilt(idx));   % variation in window
    
    if stdWin < 0.05
        act = "Flat Surface";   % no movement
    else
        [pks,~] = findpeaks(aFilt(idx),'MinPeakHeight',thr,'MinPeakDistance',round(fs*0.4));
        if numel(pks) < 2
            act = "Idle";
        else
            freq = numel(pks)/win;   % steps/sec
            amp = mean(pks);      % avg step amplitude
            
            if freq > 1.5 && freq < 2.5 && amp<2 
                act="Walking";
            elseif  freq >= 2 && amp >= 1.5 && accMean > 0
                act="Stairs Up";
            elseif freq >= 2 && amp >= 1 && accMean < 0
                act="Stairs Down";
            else
                act="Unknown";
            end

        end
    end
    activityData(idx) = act;
end

%% ================== PLOTS ==================
figure;

% (311) Raw
subplot(3,1,1);
plot(t,a,'b');
title('Raw Acceleration Magnitude');
xlabel('Time (s)'); ylabel('Accel (m/s^2)');

% (312) Filtered + Steps
subplot(3,1,2);
plot(t,aFilt,'k'); hold on;
yline(thr,'--r','Threshold');
plot(t(loc),pk,'ro');
title('Filtered Acceleration with Detected Steps');
xlabel('Time (s)'); ylabel('Accel (m/s^2)');
legend('Filtered','Threshold','Steps');

% (313) Activity
subplot(3,1,3); hold on;
if any(activityData=="Flat Surface")
    plot(t(activityData=="Flat Surface"), 0*ones(sum(activityData=="Flat Surface"),1),'m.','DisplayName','Flat Surface');
end
if any(activityData=="Idle")
    plot(t(activityData=="Idle"), -0.5*ones(sum(activityData=="Idle"),1),'k.','DisplayName','Idle');
end
if any(activityData=="Walking")
    plot(t(activityData=="Walking"), 1*ones(sum(activityData=="Walking"),1),'g.','DisplayName','Walking');
end
if any(activityData=="Stairs Up")
    plot(t(activityData=="Stairs Up"), 2*ones(sum(activityData=="Stairs Up"),1),'r.','DisplayName','Stairs Up');
end
if any(activityData=="Stairs Down")
    plot(t(activityData=="Stairs Down"), 3*ones(sum(activityData=="Stairs Down"),1),'b.','DisplayName','Stairs Down');
end
title('Activity Classification Over Time');
xlabel('Time (s)'); ylabel('Activity');
yticks([-0.5 0 1 2 3]); 
yticklabels({'Idle','Flat','Walking','Stairs Up','Stairs Down'});
legend show;

%% Step 4: Activity Summary
disp("===== Activity Summary =====");
activities = unique(activityData);
for i = 1:length(activities)
    act = activities(i);
    duration = sum(activityData==act)/fs;
    fprintf("%s : %.1f sec\n", act, duration);
end

