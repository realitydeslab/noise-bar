package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/faiface/beep"
	"github.com/faiface/beep/effects"
	"github.com/faiface/beep/speaker"
	"github.com/getlantern/systray"
)

type Sound struct {
	Name     string
	Path     string
	MenuItem *systray.MenuItem
}

func AddSound(parent *systray.MenuItem, name string, path string, icon []byte) Sound {
	item := parent.AddSubMenuItem(name, "Play "+name)
	item.SetIcon(icon)

	return Sound{
		Name:     name,
		Path:     path,
		MenuItem: item,
	}
}

type App struct {
	mu       sync.Mutex
	streamer *beep.StreamSeekCloser
	mQuit    *systray.MenuItem
	mStop    *systray.MenuItem
	sounds   []Sound

	workIdx        int
	breakIdx       int
	workItems      []*systray.MenuItem
	breakItems     []*systray.MenuItem
	workDurItems   []*systray.MenuItem
	breakDurItems  []*systray.MenuItem
	durSecs        []int
	durLabels      []string
	workDurIdx     int
	breakDurIdx    int
	mSounds        *systray.MenuItem
	mPomodoro      *systray.MenuItem
	mWorkMenu      *systray.MenuItem
	mBreakMenu     *systray.MenuItem
	mWorkDurMenu   *systray.MenuItem
	mBreakDurMenu  *systray.MenuItem
	mPomoToggle    *systray.MenuItem
	mLoop          *systray.MenuItem
	mLaunchAtLogin *systray.MenuItem
	loop           bool
	pomoCancel     chan struct{}
	pomoRunning    bool
}

func (a *App) OnTrayReady() {
	systray.SetIcon(trayIcon)
	systray.SetTitle("")
	systray.SetTooltip("Background noise machine")

	mSounds := systray.AddMenuItem("Sounds", "Pick a sound")
	a.mSounds = mSounds
	a.sounds = append(a.sounds, AddSound(mSounds, "Airplane", "./sounds/air-plane.ogg", airPlane))
	a.sounds = append(a.sounds, AddSound(mSounds, "Birds", "./sounds/birds-tree.ogg", birdsTree))
	a.sounds = append(a.sounds, AddSound(mSounds, "Brown noise", "./sounds/brown-noise3.ogg", brownNoise3))
	a.sounds = append(a.sounds, AddSound(mSounds, "Cave", "./sounds/cave-drops.ogg", cave))
	a.sounds = append(a.sounds, AddSound(mSounds, "Coffee", "./sounds/coffee.ogg", coffee))
	a.sounds = append(a.sounds, AddSound(mSounds, "Drops", "./sounds/drops.ogg", drops))
	a.sounds = append(a.sounds, AddSound(mSounds, "Fire", "./sounds/fire.ogg", fire))
	a.sounds = append(a.sounds, AddSound(mSounds, "Leaves", "./sounds/leaves.ogg", leaves))
	a.sounds = append(a.sounds, AddSound(mSounds, "Night", "./sounds/night.ogg", night))
	a.sounds = append(a.sounds, AddSound(mSounds, "Rain", "./sounds/rain.ogg", rain))
	a.sounds = append(a.sounds, AddSound(mSounds, "Storm", "./sounds/storm.ogg", storm))
	a.sounds = append(a.sounds, AddSound(mSounds, "Stream water", "./sounds/stream-water.ogg", streamWater))
	a.sounds = append(a.sounds, AddSound(mSounds, "Train", "./sounds/train.ogg", train))
	a.sounds = append(a.sounds, AddSound(mSounds, "Underwater", "./sounds/underwater.ogg", underwater))
	a.sounds = append(a.sounds, AddSound(mSounds, "Washing machine", "./sounds/washing-machine.ogg", washingMachine))
	a.sounds = append(a.sounds, AddSound(mSounds, "Waterfall", "./sounds/waterfall.ogg", waterfall))
	a.sounds = append(a.sounds, AddSound(mSounds, "Waves", "./sounds/waves.ogg", waves))
	a.sounds = append(a.sounds, AddSound(mSounds, "Wind", "./sounds/wind.ogg", wind))

	a.workIdx = 2
	a.breakIdx = 1
	a.loop = true
	a.durSecs = []int{60, 120, 300, 600, 900, 1500}
	a.durLabels = []string{"1 minute", "2 minutes", "5 minutes", "10 minutes", "15 minutes", "25 minutes"}
	a.workDurIdx = 5
	a.breakDurIdx = 2

	a.mPomodoro = systray.AddMenuItem(a.pomodoroTitle(), "Pomodoro timer")
	a.mWorkMenu = a.mPomodoro.AddSubMenuItem("Work sound: "+a.sounds[a.workIdx].Name, "")
	a.mBreakMenu = a.mPomodoro.AddSubMenuItem("Break sound: "+a.sounds[a.breakIdx].Name, "")
	for i, sound := range a.sounds {
		w := a.mWorkMenu.AddSubMenuItemCheckbox(sound.Name, "", i == a.workIdx)
		b := a.mBreakMenu.AddSubMenuItemCheckbox(sound.Name, "", i == a.breakIdx)
		a.workItems = append(a.workItems, w)
		a.breakItems = append(a.breakItems, b)
	}
	a.mWorkDurMenu = a.mPomodoro.AddSubMenuItem("Work duration: "+a.durLabels[a.workDurIdx], "")
	a.mBreakDurMenu = a.mPomodoro.AddSubMenuItem("Break duration: "+a.durLabels[a.breakDurIdx], "")
	for i, label := range a.durLabels {
		w := a.mWorkDurMenu.AddSubMenuItemCheckbox(label, "", i == a.workDurIdx)
		b := a.mBreakDurMenu.AddSubMenuItemCheckbox(label, "", i == a.breakDurIdx)
		a.workDurItems = append(a.workDurItems, w)
		a.breakDurItems = append(a.breakDurItems, b)
	}
	a.mLoop = a.mPomodoro.AddSubMenuItemCheckbox("Loop", "Repeat work/break cycle indefinitely", a.loop)
	a.mPomoToggle = a.mPomodoro.AddSubMenuItem("Start Pomodoro", "Start work/break cycle")

	systray.AddSeparator()
	a.mStop = systray.AddMenuItem("Stop", "Stop the noise")
	a.mLaunchAtLogin = systray.AddMenuItemCheckbox("Launch at login", "Open NoiseBar automatically when you log in", isLoginItem())
	a.mQuit = systray.AddMenuItem("Quit", "Quit NoiseBar")

	for _, sound := range a.sounds {
		go a.HandleSoundButton(sound)
	}
	for i := range a.sounds {
		go a.HandleWorkPick(i)
		go a.HandleBreakPick(i)
	}
	for i := range a.durSecs {
		go a.HandleWorkDurPick(i)
		go a.HandleBreakDurPick(i)
	}

	go a.HandleShutdownSignals()
	go a.HandleStopSound()
	go a.HandleLoopToggle()
	go a.HandlePomodoroToggle()
	go a.HandleLaunchAtLoginToggle()
}

func (a *App) OnTrayQuit() {
	a.mu.Lock()
	if a.streamer != nil {
		(*a.streamer).Close()
	}
	a.mu.Unlock()
	speaker.Close()

	os.Exit(0)
}

func (a *App) HandleShutdownSignals() {
	shutdownSignal := make(chan os.Signal, 1)
	signal.Notify(shutdownSignal, syscall.SIGINT, syscall.SIGTERM)

	select {
	case <-shutdownSignal:
	case <-a.mQuit.ClickedCh:
	}

	systray.Quit()
}

func (a *App) HandleStopSound() {
	for {
		<-a.mStop.ClickedCh

		a.cancelPomodoro()
		a.stopAudio()
	}
}

func (a *App) HandleSoundButton(sound Sound) {
	for {
		<-sound.MenuItem.ClickedCh
		a.cancelPomodoro()
		a.playSound(sound)
	}
}

func (a *App) playSound(sound Sound) {
	streamer, _, err := getStreamer(sound.Path)
	if err != nil {
		return
	}

	a.mu.Lock()
	defer a.mu.Unlock()

	speaker.Clear()
	if a.streamer != nil {
		(*a.streamer).Close()
	}
	a.streamer = &streamer
	if a.mSounds != nil {
		a.mSounds.SetTitle("Sounds: " + sound.Name)
	}

	volume := &effects.Volume{
		Streamer: beep.Loop(-1, streamer),
		Base:     2,
		Volume:   0,
		Silent:   false,
	}
	speaker.Play(volume)
}

func (a *App) stopAudio() {
	a.mu.Lock()
	defer a.mu.Unlock()
	speaker.Clear()
	if a.streamer != nil {
		(*a.streamer).Close()
		a.streamer = nil
	}
	if a.mSounds != nil {
		a.mSounds.SetTitle("Sounds")
	}
}

func (a *App) pomodoroTitle() string {
	return fmt.Sprintf("Pomodoro (%d/%d)", a.durSecs[a.workDurIdx]/60, a.durSecs[a.breakDurIdx]/60)
}

func (a *App) HandleWorkPick(idx int) {
	for {
		<-a.workItems[idx].ClickedCh
		a.mu.Lock()
		for j, item := range a.workItems {
			if j == idx {
				item.Check()
			} else {
				item.Uncheck()
			}
		}
		a.workIdx = idx
		a.mWorkMenu.SetTitle("Work sound: " + a.sounds[idx].Name)
		a.mu.Unlock()
	}
}

func (a *App) HandleBreakPick(idx int) {
	for {
		<-a.breakItems[idx].ClickedCh
		a.mu.Lock()
		for j, item := range a.breakItems {
			if j == idx {
				item.Check()
			} else {
				item.Uncheck()
			}
		}
		a.breakIdx = idx
		a.mBreakMenu.SetTitle("Break sound: " + a.sounds[idx].Name)
		a.mu.Unlock()
	}
}

func (a *App) HandleWorkDurPick(idx int) {
	for {
		<-a.workDurItems[idx].ClickedCh
		a.mu.Lock()
		for j, item := range a.workDurItems {
			if j == idx {
				item.Check()
			} else {
				item.Uncheck()
			}
		}
		a.workDurIdx = idx
		a.mWorkDurMenu.SetTitle("Work duration: " + a.durLabels[idx])
		a.mPomodoro.SetTitle(a.pomodoroTitle())
		a.mu.Unlock()
	}
}

func (a *App) HandleBreakDurPick(idx int) {
	for {
		<-a.breakDurItems[idx].ClickedCh
		a.mu.Lock()
		for j, item := range a.breakDurItems {
			if j == idx {
				item.Check()
			} else {
				item.Uncheck()
			}
		}
		a.breakDurIdx = idx
		a.mBreakDurMenu.SetTitle("Break duration: " + a.durLabels[idx])
		a.mPomodoro.SetTitle(a.pomodoroTitle())
		a.mu.Unlock()
	}
}

func (a *App) HandleLoopToggle() {
	for {
		<-a.mLoop.ClickedCh
		a.mu.Lock()
		if a.mLoop.Checked() {
			a.mLoop.Uncheck()
			a.loop = false
		} else {
			a.mLoop.Check()
			a.loop = true
		}
		a.mu.Unlock()
	}
}

func (a *App) HandlePomodoroToggle() {
	for {
		<-a.mPomoToggle.ClickedCh
		a.mu.Lock()
		if a.pomoRunning {
			a.pomoRunning = false
			close(a.pomoCancel)
			a.pomoCancel = nil
			a.mPomoToggle.SetTitle("Start Pomodoro")
			systray.SetTitle("")
			a.mu.Unlock()
		} else {
			a.pomoRunning = true
			a.pomoCancel = make(chan struct{})
			a.mPomoToggle.SetTitle("Stop Pomodoro")
			cancel := a.pomoCancel
			a.mu.Unlock()
			go a.RunPomodoro(cancel)
		}
	}
}

func (a *App) cancelPomodoro() {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.pomoRunning {
		a.pomoRunning = false
		close(a.pomoCancel)
		a.pomoCancel = nil
		a.mPomoToggle.SetTitle("Start Pomodoro")
		systray.SetTitle("")
	}
}

func (a *App) RunPomodoro(cancel chan struct{}) {
	for {
		a.mu.Lock()
		w := a.sounds[a.workIdx]
		workDur := a.durSecs[a.workDurIdx]
		a.mu.Unlock()
		a.playSound(w)
		if !a.countdown(workDur, cancel) {
			return
		}

		a.mu.Lock()
		b := a.sounds[a.breakIdx]
		breakDur := a.durSecs[a.breakDurIdx]
		a.mu.Unlock()
		a.playSound(b)
		if !a.countdown(breakDur, cancel) {
			return
		}

		a.mu.Lock()
		loop := a.loop
		a.mu.Unlock()
		if !loop {
			a.cancelPomodoro()
			a.stopAudio()
			return
		}
	}
}

func appBundlePath() string {
	ex, err := os.Executable()
	if err != nil {
		return ""
	}
	return filepath.Dir(filepath.Dir(filepath.Dir(ex)))
}

func isLoginItem() bool {
	out, err := exec.Command("osascript", "-e",
		`tell application "System Events" to get the name of every login item`).Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(out), "NoiseBar")
}

func addLoginItem() error {
	path := appBundlePath()
	script := fmt.Sprintf(
		`tell application "System Events" to make login item at end with properties {path:"%s", hidden:false}`,
		path)
	return exec.Command("osascript", "-e", script).Run()
}

func removeLoginItem() error {
	return exec.Command("osascript", "-e",
		`tell application "System Events" to delete login item "NoiseBar"`).Run()
}

func (a *App) HandleLaunchAtLoginToggle() {
	for {
		<-a.mLaunchAtLogin.ClickedCh
		if a.mLaunchAtLogin.Checked() {
			removeLoginItem()
		} else {
			addLoginItem()
		}
		if isLoginItem() {
			a.mLaunchAtLogin.Check()
		} else {
			a.mLaunchAtLogin.Uncheck()
		}
	}
}

func (a *App) countdown(seconds int, cancel chan struct{}) bool {
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()
	for s := seconds; s > 0; s-- {
		systray.SetTitle(fmt.Sprintf("%d:%02d", s/60, s%60))
		select {
		case <-ticker.C:
		case <-cancel:
			return false
		}
	}
	return true
}
