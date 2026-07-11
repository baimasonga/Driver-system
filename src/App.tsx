import React, { useState, useEffect } from "react";
import { motion } from "motion/react";
import {
  Car,
  User,
  Users,
  Navigation,
  Flame,
  FileText,
  Shield,
  Activity,
  AlertTriangle,
  CheckCircle,
  Clock,
  MapPin,
  Compass,
  ArrowRight,
  Sparkles,
  Smartphone,
  Laptop,
  HelpCircle,
  RefreshCw,
  Lock,
  ExternalLink
} from "lucide-react";

import {
  Vehicle,
  Driver,
  Trip,
  FuelRequest,
  MaintenanceRequest,
  Exception,
  AuditLog,
  PolicyRule,
  SparePart,
  Tyre,
  Incident,
  TripStatus
} from "./types";

import {
  defaultVehicles,
  defaultDrivers,
  defaultTrips,
  defaultFuelRequests,
  defaultMaintenanceRequests,
  defaultExceptions,
  defaultIncidents,
  defaultAuditLogs,
  defaultPolicyRules,
  defaultSpareParts,
  defaultTyres
} from "./mockData";

import MobileSimulator from "./components/MobileSimulator";
import WebDashboard from "./components/WebDashboard";

export default function App() {
  // Role Selector: 'manager' | 'driver' | 'gate' | 'finance' | 'auditor'
  const [activeRole, setActiveRole] = useState<string>("manager");
  const [selectedDriverId, setSelectedDriverId] = useState<string>("d3"); // Default to Musa Conteh (High Risk for easy demo)
  const [showGuide, setShowGuide] = useState<boolean>(true);

  // Core Database States loaded from LocalStorage or Defaults
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [fuelRequests, setFuelRequests] = useState<FuelRequest[]>([]);
  const [maintenanceRequests, setMaintenanceRequests] = useState<MaintenanceRequest[]>([]);
  const [exceptions, setExceptions] = useState<Exception[]>([]);
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [policyRules, setPolicyRules] = useState<PolicyRule[]>([]);
  const [spareParts, setSpareParts] = useState<SparePart[]>([]);
  const [tyres, setTyres] = useState<Tyre[]>([]);

  // Load from local storage on mount
  useEffect(() => {
    const localVehicles = localStorage.getItem("fleet_vehicles");
    const localDrivers = localStorage.getItem("fleet_drivers");
    const localTrips = localStorage.getItem("fleet_trips");
    const localFuel = localStorage.getItem("fleet_fuel_requests");
    const localMaint = localStorage.getItem("fleet_maintenance_requests");
    const localExceptions = localStorage.getItem("fleet_exceptions");
    const localIncidents = localStorage.getItem("fleet_incidents");
    const localLogs = localStorage.getItem("fleet_audit_logs");
    const localPolicies = localStorage.getItem("fleet_policy_rules");
    const localParts = localStorage.getItem("fleet_spare_parts");
    const localTyres = localStorage.getItem("fleet_tyres");

    if (
      localVehicles && localDrivers && localTrips && localFuel && 
      localMaint && localExceptions && localIncidents && localLogs && 
      localPolicies && localParts && localTyres
    ) {
      setVehicles(JSON.parse(localVehicles));
      setDrivers(JSON.parse(localDrivers));
      setTrips(JSON.parse(localTrips));
      setFuelRequests(JSON.parse(localFuel));
      setMaintenanceRequests(JSON.parse(localMaint));
      setExceptions(JSON.parse(localExceptions));
      setIncidents(JSON.parse(localIncidents));
      setAuditLogs(JSON.parse(localLogs));
      setPolicyRules(JSON.parse(localPolicies));
      setSpareParts(JSON.parse(localParts));
      setTyres(JSON.parse(localTyres));
    } else {
      resetToDefault();
    }
  }, []);

  // Save states helper
  const saveState = (key: string, data: any) => {
    localStorage.setItem(key, JSON.stringify(data));
  };

  const updateVehicles = (data: Vehicle[]) => {
    setVehicles(data);
    saveState("fleet_vehicles", data);
  };

  const updateTrips = (data: Trip[]) => {
    setTrips(data);
    saveState("fleet_trips", data);
  };

  const updateFuelRequests = (data: FuelRequest[]) => {
    setFuelRequests(data);
    saveState("fleet_fuel_requests", data);
  };

  const updateMaintenanceRequests = (data: MaintenanceRequest[]) => {
    setMaintenanceRequests(data);
    saveState("fleet_maintenance_requests", data);
  };

  const updateExceptions = (data: Exception[]) => {
    setExceptions(data);
    saveState("fleet_exceptions", data);
  };

  const updateIncidents = (data: Incident[]) => {
    setIncidents(data);
    saveState("fleet_incidents", data);
  };

  const updatePolicyRules = (data: PolicyRule[]) => {
    setPolicyRules(data);
    saveState("fleet_policy_rules", data);
  };

  const updateSpareParts = (data: SparePart[]) => {
    setSpareParts(data);
    saveState("fleet_spare_parts", data);
  };

  // Black Box Immutable Log Entry Generator
  const handleAddAuditLog = (user: string, entityType: string, entityId: string, details: string) => {
    const newLog: AuditLog = {
      id: "log-" + Math.random().toString(36).substr(2, 9),
      timestamp: new Date().toISOString(),
      userId: user,
      userRole: user === "System" ? "Security Core" : activeRole.toUpperCase(),
      action: entityType === "Exception" ? "ALERT DETECTED" : "MODIFIED RECORD",
      entityType,
      entityId,
      details
    };
    const updated = [newLog, ...auditLogs];
    setAuditLogs(updated);
    saveState("fleet_audit_logs", updated);
  };

  const resetToDefault = () => {
    setVehicles(defaultVehicles);
    setDrivers(defaultDrivers);
    setTrips(defaultTrips);
    setFuelRequests(defaultFuelRequests);
    setMaintenanceRequests(defaultMaintenanceRequests);
    setExceptions(defaultExceptions);
    setIncidents(defaultIncidents);
    setAuditLogs(defaultAuditLogs);
    setPolicyRules(defaultPolicyRules);
    setSpareParts(defaultSpareParts);
    setTyres(defaultTyres);

    localStorage.setItem("fleet_vehicles", JSON.stringify(defaultVehicles));
    localStorage.setItem("fleet_drivers", JSON.stringify(defaultDrivers));
    localStorage.setItem("fleet_trips", JSON.stringify(defaultTrips));
    localStorage.setItem("fleet_fuel_requests", JSON.stringify(defaultFuelRequests));
    localStorage.setItem("fleet_maintenance_requests", JSON.stringify(defaultMaintenanceRequests));
    localStorage.setItem("fleet_exceptions", JSON.stringify(defaultExceptions));
    localStorage.setItem("fleet_incidents", JSON.stringify(defaultIncidents));
    localStorage.setItem("fleet_audit_logs", JSON.stringify(defaultAuditLogs));
    localStorage.setItem("fleet_policy_rules", JSON.stringify(defaultPolicyRules));
    localStorage.setItem("fleet_spare_parts", JSON.stringify(defaultSpareParts));
    localStorage.setItem("fleet_tyres", JSON.stringify(defaultTyres));
  };

  const currentDriver = drivers.find(d => d.id === selectedDriverId) || drivers[0];

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 flex flex-col font-sans selection:bg-amber-500 selection:text-neutral-950">
      
      {/* Top Controls: Role Selection & Guidance toggles */}
      <header className="bg-neutral-900/90 border-b border-neutral-800 px-6 py-4 flex flex-col lg:flex-row justify-between items-center gap-4 z-30">
        <div className="flex items-center space-x-3 shrink-0">
          <div className="w-10 h-10 rounded-xl bg-amber-500 flex items-center justify-center text-neutral-950 shadow-md">
            <Shield className="w-5.5 h-5.5" />
          </div>
          <div>
            <h1 className="text-sm font-black uppercase tracking-wider text-white">Driver & Fleet Accountability Management</h1>
            <p className="text-[10px] text-neutral-400 font-mono">Anti-Theft, Odometer Fraud Verification, and Maintenance Audits</p>
          </div>
        </div>

        {/* Interactive Testing Center (Switch perspectives easily!) */}
        <div className="flex flex-wrap items-center gap-3 bg-neutral-950/80 p-1.5 rounded-2xl border border-neutral-800">
          <span className="text-[10px] text-neutral-400 uppercase font-bold px-2 font-mono">Select View:</span>
          
          <button
            onClick={() => {
              setActiveRole("manager");
              setShowGuide(false);
            }}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center space-x-1.5 transition ${
              activeRole === "manager" ? "bg-amber-500 text-neutral-950" : "text-neutral-300 hover:bg-neutral-900"
            }`}
          >
            <Laptop className="w-3.5 h-3.5" />
            <span>Web Control Panel</span>
          </button>

          <button
            onClick={() => {
              setActiveRole("driver");
              setShowGuide(false);
            }}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center space-x-1.5 transition ${
              activeRole === "driver" ? "bg-amber-500 text-neutral-950" : "text-neutral-300 hover:bg-neutral-900"
            }`}
          >
            <Smartphone className="w-3.5 h-3.5" />
            <span>Mobile App Simulator</span>
          </button>

          {activeRole === "driver" && (
            <div className="flex items-center space-x-1 pl-2 border-l border-neutral-800">
              <span className="text-[10px] text-neutral-400 font-mono">Active Driver:</span>
              <select
                value={selectedDriverId}
                onChange={(e) => setSelectedDriverId(e.target.value)}
                className="bg-neutral-900 border border-neutral-800 rounded px-2 py-0.5 text-xs text-white font-mono focus:outline-none"
              >
                {drivers.map(d => (
                  <option key={d.id} value={d.id}>{d.name} {d.id === "d3" ? "(High Risk Demo)" : ""}</option>
                ))}
              </select>
            </div>
          )}
        </div>

        {/* Support Tools */}
        <div className="flex items-center space-x-2 shrink-0">
          <button
            onClick={() => setShowGuide(!showGuide)}
            className="flex items-center space-x-1 px-3 py-1.5 bg-neutral-850 hover:bg-neutral-800 rounded-xl text-xs text-neutral-300 border border-neutral-800 transition"
          >
            <HelpCircle className="w-3.5 h-3.5" />
            <span>Interactive Demo Guide</span>
          </button>
        </div>
      </header>

      {/* Interactive Demonstration Guidelines Guide Drawer (collapsible) */}
      {showGuide && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-neutral-900 border-b border-neutral-800 p-5 px-6 space-y-3 relative overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/5 rounded-full blur-3xl pointer-events-none"></div>
          <div className="flex items-start space-x-3 max-w-5xl">
            <Sparkles className="w-5 h-5 text-amber-500 shrink-0 mt-0.5" />
            <div className="space-y-1.5">
              <h3 className="text-xs font-black uppercase text-white tracking-wider">How to test the anti-fraud exception mechanism</h3>
              <p className="text-xs text-neutral-300 leading-relaxed">
                Organizations lose thousands of dollars on unverified driver claims. This double-app architecture (Driver Mobile app & Web Management console) completely secures operations. Try this step-by-step audit scenario:
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-2 text-[11px]">
                <div className="bg-neutral-950 p-2.5 rounded-xl border border-neutral-850 space-y-1">
                  <span className="font-bold text-amber-500">Step 1: Driver Falsification</span>
                  <p className="text-neutral-400">
                    Set role to <strong>Mobile App</strong> & select <strong>Musa Conteh</strong>. Finish his active Trip. He logs 200KM on odometer instead of the actual GPS logged 120KM.
                  </p>
                </div>
                <div className="bg-neutral-950 p-2.5 rounded-xl border border-neutral-850 space-y-1">
                  <span className="font-bold text-amber-500">Step 2: Log Refuel Discrepancy</span>
                  <p className="text-neutral-400">
                    Still as Musa, click <strong>Request Fuel</strong>. Request 65 Liters. The fraud checker flags a major fuel consumption variance rate (1.8 KM/L vs expected 11.5 KM/L).
                  </p>
                </div>
                <div className="bg-neutral-950 p-2.5 rounded-xl border border-neutral-850 space-y-1">
                  <span className="font-bold text-amber-500">Step 3: Investigate & Seal</span>
                  <p className="text-neutral-400">
                    Switch view to <strong>Web Control Panel</strong>. Go to <strong>Exceptions</strong> or <strong>Blackbox Trail</strong> to review the alerts, enter findings, and seal the file.
                  </p>
                </div>
              </div>
            </div>
          </div>
          <button
            onClick={() => setShowGuide(false)}
            className="absolute top-4 right-6 text-xs text-neutral-400 hover:text-white"
          >
            Dismiss
          </button>
        </motion.div>
      )}

      {/* Main Dual App Wrapper Container */}
      <div className="flex-1 flex flex-col xl:flex-row min-h-0 overflow-hidden p-6 gap-6">
        
        {/* If Manager or Admin selected: Show full Web Dashboard. If Driver selected, show side-by-side or fill with Phone Simulator */}
        {activeRole === "manager" ? (
          <div className="flex-1 flex flex-col min-h-0">
            <WebDashboard
              vehicles={vehicles}
              drivers={drivers}
              trips={trips}
              fuelRequests={fuelRequests}
              maintenanceRequests={maintenanceRequests}
              exceptions={exceptions}
              incidents={incidents}
              auditLogs={auditLogs}
              policyRules={policyRules}
              spareParts={spareParts}
              tyres={tyres}
              activeRole="Fleet Manager"
              onUpdateVehicles={updateVehicles}
              onUpdateTrips={updateTrips}
              onUpdateFuelRequests={updateFuelRequests}
              onUpdateMaintenanceRequests={updateMaintenanceRequests}
              onUpdateExceptions={updateExceptions}
              onUpdateIncidents={updateIncidents}
              onUpdatePolicyRules={updatePolicyRules}
              onUpdateSpareParts={updateSpareParts}
              onAddAuditLog={handleAddAuditLog}
              onResetData={resetToDefault}
            />
          </div>
        ) : (
          <div className="flex-1 flex flex-col lg:flex-row gap-6 min-h-0 items-stretch">
            
            {/* Mobile App View Frame */}
            <div className="flex-1 flex items-center justify-center bg-neutral-900 border border-neutral-800 rounded-3xl p-4 shrink-0">
              <MobileSimulator
                vehicles={vehicles}
                drivers={drivers}
                trips={trips}
                fuelRequests={fuelRequests}
                maintenanceRequests={maintenanceRequests}
                exceptions={exceptions}
                incidents={incidents}
                auditLogs={auditLogs}
                currentDriver={currentDriver}
                onUpdateVehicles={updateVehicles}
                onUpdateTrips={updateTrips}
                onUpdateFuelRequests={updateFuelRequests}
                onUpdateMaintenanceRequests={updateMaintenanceRequests}
                onUpdateExceptions={updateExceptions}
                onUpdateIncidents={updateIncidents}
                onAddAuditLog={handleAddAuditLog}
              />
            </div>

            {/* Quick telemetry reference shown next to smartphone simulator for seamless developer walkthrough */}
            <div className="flex-1 bg-neutral-900 border border-neutral-800 rounded-3xl p-6 overflow-y-auto space-y-4">
              <div className="flex justify-between items-center pb-3 border-b border-neutral-800">
                <span className="text-xs font-black uppercase text-white tracking-wider flex items-center">
                  <Activity className="w-4 h-4 mr-1 text-amber-500" /> Live Database Telemetry Feed
                </span>
                <span className="text-[10px] bg-neutral-950 px-2 py-0.5 border border-neutral-800 rounded text-neutral-400 font-mono">
                  Sync status: active
                </span>
              </div>

              <div className="space-y-3 text-xs">
                <div>
                  <h4 className="font-bold text-neutral-300">Driver Simulation Scenario Instructions:</h4>
                  <p className="text-neutral-400 leading-relaxed">
                    You can simulate driver tasks on the smartphone. Since the smartphone is bound directly to the database state, turning offline, starting a route, or failing a vehicle inspection checklist generates instantly traceable events. Try toggling <strong>Offline Mode</strong> on the phone status bar to test how reports sync up later!
                  </p>
                </div>

                <div className="bg-neutral-950 p-4 rounded-2xl border border-neutral-800/60 space-y-2">
                  <span className="text-[10px] text-amber-500 font-mono uppercase block">CURRENT SIMULATED VEHICLE LOGS</span>
                  <p className="font-semibold text-white">{vehicles.find(v => v.assignedDriverId === currentDriver.id)?.registrationNumber || "v1"} ({vehicles.find(v => v.assignedDriverId === currentDriver.id)?.make || "Toyota"})</p>
                  <p className="text-[11px] text-neutral-400 leading-relaxed">
                    This vehicle has expected mileage of <strong>{vehicles.find(v => v.assignedDriverId === currentDriver.id)?.expectedFuelConsumption || "8.5"} km/liter</strong>. Musa's vehicle has an active tamper trigger configured if the GPS connector is disconnected.
                  </p>
                </div>

                <div className="pt-2 border-t border-neutral-800">
                  <button
                    onClick={() => {
                      setActiveRole("manager");
                    }}
                    className="w-full bg-amber-500 hover:bg-amber-600 text-neutral-950 font-extrabold text-xs py-2.5 rounded-xl flex items-center justify-center space-x-1"
                  >
                    <span>Switch to Management Dashboard View</span>
                    <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>

          </div>
        )}

      </div>

    </div>
  );
}
